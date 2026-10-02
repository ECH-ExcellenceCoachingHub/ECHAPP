const ChatMessage = require('../models/ChatMessage');
const Conversation = require('../models/Conversation');
const Enrollment = require('../models/Enrollment');
const Result = require('../models/Result');
const User = require('../models/User');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const TTSService = require('../services/tts.service');
const GrokService = require('../services/grok_service');
const s3Service = require('../services/s3.service');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');

// Multer storage for file uploads (memory, max 20 MB)
const _uploadStorage = multer.memoryStorage();
const _upload = multer({
  storage: _uploadStorage,
  limits: { fileSize: 20 * 1024 * 1024 },
});
const uploadSingle = _upload.single('file');

// ─── In-process caches ───────────────────────────────────────────────────────
// AI response cache: key = sha256(systemPrompt + lastUserMsg), TTL 10 min, max 200 entries
const _aiCache = new Map();
const AI_CACHE_TTL = 10 * 60 * 1000;   // 10 minutes
const AI_CACHE_MAX = 200;

// Document text-extraction cache: key = sha256(fileBuffer), TTL 30 min, max 50 entries
const _docCache = new Map();
const DOC_CACHE_TTL = 30 * 60 * 1000;  // 30 minutes
const DOC_CACHE_MAX = 50;

function _sha256(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

function _cacheGet(map, key) {
  const entry = map.get(key);
  if (!entry) return null;
  if (Date.now() - entry.ts > entry.ttl) { map.delete(key); return null; }
  return entry.value;
}

function _cacheSet(map, key, value, ttl, max) {
  if (map.size >= max) {
    // Evict the oldest entry
    map.delete(map.keys().next().value);
  }
  map.set(key, { value, ts: Date.now(), ttl });
}

class ChatController {
  // Get user's conversation history
  static async getUserConversations(req, res) {
    try {
      const userId = req.user?._id.toString();
      
      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const conversations = await Conversation.getUserConversations(userId, 20);
      
      res.json({
        success: true,
        conversations: conversations.map(conv => ({
          id: conv._id,
          title: conv.title,
          preview: conv.preview,
          lastActivity: conv.lastActivity,
          messageCount: conv.messageCount,
          courseId: conv.courseId?._id || conv.courseId,
          lessonId: conv.lessonId?._id || conv.lessonId,
          sectionTitle: conv.sectionTitle,
          createdAt: conv.createdAt,
          updatedAt: conv.updatedAt
        }))
      });
    } catch (error) {
      console.error('Error fetching user conversations:', error);
      res.status(500).json({ 
        error: 'Failed to fetch conversations',
        details: error.message 
      });
    }
  }

  // Get specific conversation messages
  static async getConversationMessages(req, res) {
    try {
      const { conversationId } = req.params;
      const userId = req.user?._id.toString();
      const limit = parseInt(req.query.limit) || 50;

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      // Check if conversationId is a valid ObjectId or a customId
      const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
      let conversation;

      if (isValidObjectId) {
        conversation = await Conversation.findById(conversationId);
      } else {
        conversation = await Conversation.findOne({ customId: conversationId, userId });
      }
      
      if (!conversation || conversation.userId !== userId) {
        return res.status(404).json({ 
          error: 'Conversation not found' 
        });
      }

      const messages = await ChatMessage.getConversationHistory(conversation._id, limit);
      
      res.json({
        success: true,
        conversation: {
          id: conversation.customId || conversation._id,
          title: conversation.title,
          context: conversation.getContext()
        },
        messages: messages.map(msg => ({
          id: msg._id,
          sender: msg.sender,
          message: msg.message,
          messageType: msg.messageType,
          timestamp: msg.timestamp,
          formattedTimestamp: msg.formattedTimestamp,
          isContextAware: msg.isContextAware
        }))
      });
    } catch (error) {
      console.error('Error fetching conversation messages:', error);
      res.status(500).json({ 
        error: 'Failed to fetch messages',
        details: error.message 
      });
    }
  }

  // Create new conversation or get existing one
  static async createConversation(req, res) {
    try {
      const userId = req.user?._id.toString();
      const { context } = req.body;
      const safeContext = context || {};

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const conversation = await Conversation.getOrCreateConversation(userId, safeContext);
      
      // If it's a new conversation, save it
      if (conversation.isNew) {
        await conversation.save();
      }

      res.json({
        success: true,
        conversation: {
          id: conversation._id,
          title: conversation.title,
          context: conversation.getContext(),
          messageCount: conversation.messageCount,
          createdAt: conversation.createdAt
        }
      });
    } catch (error) {
      console.error('Error creating conversation:', error);
      res.status(500).json({ 
        error: 'Failed to create conversation',
        details: error.message 
      });
    }
  }

  // Send message and get AI response
  static async sendMessage(req, res) {
    try {
      const { conversationId, message, context } = req.body;
      const safeContext = context || {};
      const userId = req.user?._id.toString();

      if (!userId) {
        return res.status(401).json({ error: 'User authentication required' });
      }

      if (!message || message.trim().length === 0) {
        return res.status(400).json({ error: 'Message is required' });
      }

      // Run all independent DB lookups in parallel
      const [enrollments, results, user, conversation] = await Promise.all([
        Enrollment.find({ userId }).populate('courseId', 'title').lean(),
        Result.find({ userId }).populate('examId', 'title').lean(),
        User.findById(userId).select('fullName role').lean(),
        (async () => {
          if (!conversationId) {
            return await Conversation.getOrCreateConversation(userId, { ...safeContext, customId: 'support_chat' });
          }
          
          const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
          if (isValidObjectId) {
            const conv = await Conversation.findById(conversationId);
            if (!conv) return null;
            return conv;
          } else {
            // For custom IDs, if not found, create it
            let conv = await Conversation.findOne({ customId: conversationId, userId });
            if (!conv) {
              conv = await Conversation.getOrCreateConversation(userId, { ...safeContext, customId: conversationId });
            }
            return conv;
          }
        })(),
      ]);

      if (!conversation || (conversationId && conversation.userId !== userId)) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      const performanceContext = {
        studentName: user?.fullName || 'Student',
        studentLevel: user?.role || 'student',
        courses: enrollments.map(e => ({
          title: e.courseId?.title,
          progress: e.progress,
          status: e.completionStatus
        })),
        examResults: results.map(r => ({
          examTitle: r.examId?.title,
          score: r.score,
          totalPoints: r.totalPoints,
          percentage: r.percentage,
          passed: r.passed
        }))
      };

      // Save user message and fetch history in parallel
      const userMessage = new ChatMessage({
        conversationId: conversation._id,
        sender: 'user',
        message: message.trim(),
        messageType: 'text',
        context: safeContext,
        isContextAware: !!context,
        metadata: { ipAddress: req.ip, userAgent: req.get('User-Agent') }
      });

      // Save before reading history. Running these in parallel let the history
      // miss the question just asked, so the AI answered the previous one.
      await userMessage.save();
      const recentMessages = await ChatMessage.getConversationHistory(conversation._id, 10);

      await conversation.incrementMessageCount();

      // Always end with the current question, even if timestamps tie in history.
      const priorMessages = recentMessages.filter(
        msg => msg._id.toString() !== userMessage._id.toString()
      );

      const messagesForAI = [
        {
          role: 'system',
          content: ChatController.createContextAwareSystemPrompt({
            ...conversation.getContext(),
            ...performanceContext,
            ...safeContext
          })
        },
        ...priorMessages.map(msg => ({
          role: msg.sender === 'user' ? 'user' : 'assistant',
          content: msg.message
        })),
        { role: 'user', content: userMessage.message }
      ];

      // Generate AI response
      const aiResponse = await ChatController.generateAIResponse(messagesForAI, safeContext);

      // Save AI message
      const aiMessage = new ChatMessage({
        conversationId: conversation._id,
        sender: 'ai',
        message: aiResponse,
        messageType: 'text',
        isContextAware: true,
        context: safeContext
      });

      // Save AI message and bump counter in parallel
      await Promise.all([aiMessage.save(), conversation.incrementMessageCount()]);

      // Respond immediately — TTS runs in background
      res.json({
        success: true,
        conversation: { id: conversation._id, title: conversation.title },
        audioUrl: null,
        messages: [
          {
            id: userMessage._id,
            sender: 'user',
            message: userMessage.message,
            timestamp: userMessage.timestamp,
            formattedTimestamp: userMessage.formattedTimestamp
          },
          {
            id: aiMessage._id,
            sender: 'ai',
            message: aiMessage.message,
            timestamp: aiMessage.timestamp,
            formattedTimestamp: aiMessage.formattedTimestamp,
            audioUrl: null
          }
        ]
      });

      // Fire TTS async — does not block the response
      ChatController._generateTTSBackground(aiResponse, aiMessage._id, req.protocol, req.get('host'));

    } catch (error) {
      console.error('Error sending message:', error);
      res.status(500).json({ error: 'Failed to send message', details: error.message });
    }
  }

  // Background TTS generation — fire-and-forget
  static _generateTTSBackground(text, messageId, protocol, host) {
    try {
      const audioDir = path.join(__dirname, '../../uploads/voice');
      if (!fs.existsSync(audioDir)) fs.mkdirSync(audioDir, { recursive: true });
      const audioFileName = `chat-response-${Date.now()}.mp3`;
      const audioFilePath = path.join(audioDir, audioFileName);
      TTSService.generateSpeech(text, audioFilePath)
        .then(generated => {
          if (generated) {
            const audioUrl = `${protocol}://${host}/uploads/voice/${audioFileName}`;
            ChatMessage.findByIdAndUpdate(messageId, { audioUrl }).catch(() => {});
          }
        })
        .catch(err => console.error('Background TTS error:', err));
    } catch (e) {
      console.error('TTS setup error:', e);
    }
  }

  // Send message with file attachment (document or image)
  static sendMessageWithFile(req, res) {
    uploadSingle(req, res, async (multerErr) => {
      if (multerErr) {
        return res.status(400).json({ error: 'File upload failed', details: multerErr.message });
      }

      try {
        const { conversationId, message, fileType } = req.body;
        let safeContext = {};
        try { safeContext = JSON.parse(req.body.context || '{}'); } catch (_) {}
        const userId = req.user?._id.toString();

        if (!userId) return res.status(401).json({ error: 'User authentication required' });
        if (!req.file) return res.status(400).json({ error: 'No file provided' });

        // Parallel: resolve conversation + user
        const [user, conversation] = await Promise.all([
          User.findById(userId).select('fullName role').lean(),
          (async () => {
            if (!conversationId) {
              return await Conversation.getOrCreateConversation(userId, { ...safeContext, customId: 'support_chat' });
            }
            
            const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
            if (isValidObjectId) {
              const conv = await Conversation.findById(conversationId);
              if (!conv) return null;
              return conv;
            } else {
              // For custom IDs, if not found, create it
              let conv = await Conversation.findOne({ customId: conversationId, userId });
              if (!conv) {
                conv = await Conversation.getOrCreateConversation(userId, { ...safeContext, customId: conversationId });
              }
              return conv;
            }
          })(),
        ]);

        if (!conversation || (conversationId && conversation.userId !== userId)) {
          return res.status(404).json({ error: 'Conversation not found' });
        }
        // Detect file type - only documents allowed
        const detectedType = 'document';

        // ── S3 upload + text extraction run in parallel ──────────────────────
        const bufferHash = _sha256(req.file.buffer);

        const [s3Result, fileContent] = await Promise.all([
          // Upload to S3 under chat-attachments/ folder
          s3Service.uploadFile(
            req.file.buffer,
            req.file.originalname,
            req.file.mimetype,
            'chat-attachments'
          ).catch(err => { console.error('S3 chat upload error:', err.message); return null; }),

          // Extract text from documents (PDF, DOCX) with cache
          (async () => {
            const cached = _cacheGet(_docCache, bufferHash);
            if (cached !== null) { console.log('[doc cache] HIT'); return cached; }
            try {
              const mime = req.file.mimetype;
              let text = '';
              
              if (mime === 'application/pdf' || req.file.originalname?.endsWith('.pdf')) {
                const pdfData = await pdfParse(req.file.buffer);
                text = pdfData.text?.substring(0, 8000) || '';
              } else if (mime.includes('word') || req.file.originalname?.match(/\.docx?$/)) {
                const r = await mammoth.extractRawText({ buffer: req.file.buffer });
                text = r.value?.substring(0, 8000) || '';
              } else {
                text = req.file.buffer.toString('utf8').substring(0, 8000);
              }
              _cacheSet(_docCache, bufferHash, text, DOC_CACHE_TTL, DOC_CACHE_MAX);
              return text;
            } catch (e) {
              console.error('Text extraction error:', e.message);
              return '';
            }
          })(),
        ]);

        const s3Url = s3Result?.url || null;
        const userPrompt = message?.trim() || `Please analyze this ${detectedType} and help me understand it.`;
        const systemContext = ChatController.createContextAwareSystemPrompt({
          studentName: user?.fullName || 'Student',
          studentLevel: user?.role || 'student',
          ...safeContext
        });

        let userMessageContent = userPrompt;
        if (detectedType === 'image') {
          userMessageContent = `${userPrompt}\n\n[The user has uploaded an image: ${req.file.originalname}${s3Url ? ` (stored at ${s3Url})` : ''}. Acknowledge that you can see it and offer analysis based on the question.]`;
        } else if (fileContent) {
          userMessageContent = `${userPrompt}\n\nDOCUMENT CONTENT:\n${fileContent}`;
        } else {
          userMessageContent = `${userPrompt}\n\n[User uploaded a file: ${req.file.originalname}. The content could not be extracted automatically. Ask them to paste the key text if needed.]`;
        }

        const messagesForAI = [
          { role: 'system', content: systemContext },
          { role: 'user', content: userMessageContent }
        ];

        // Save user message (parallel with AI call start is not possible but we
        // can at least not block on conversation.incrementMessageCount)
        const userMessage = new ChatMessage({
          conversationId: conversation._id,
          sender: 'user',
          message: userPrompt,
          messageType: detectedType === 'image' ? 'image' : 'text',
          context: safeContext,
          isContextAware: true,
          metadata: { ipAddress: req.ip, userAgent: req.get('User-Agent') }
        });
        await userMessage.save();
        await conversation.incrementMessageCount();

        // Generate AI response
        const aiResponse = await ChatController.generateAIResponse(messagesForAI, safeContext);

        const aiMessage = new ChatMessage({
          conversationId: conversation._id,
          sender: 'ai',
          message: aiResponse,
          messageType: 'text',
          isContextAware: true,
          context: safeContext
        });
        // Save AI message and bump counter in parallel
        await Promise.all([aiMessage.save(), conversation.incrementMessageCount()]);

        res.json({
          success: true,
          conversation: { id: conversation._id, title: conversation.title },
          audioUrl: null,
          messages: [
            {
              id: userMessage._id,
              sender: 'user',
              message: userMessage.message,
              timestamp: userMessage.timestamp,
              formattedTimestamp: userMessage.formattedTimestamp,
              s3Url: s3Url,           // hosted URL for display
              fileType: detectedType,
            },
            {
              id: aiMessage._id,
              sender: 'ai',
              message: aiMessage.message,
              timestamp: aiMessage.timestamp,
              formattedTimestamp: aiMessage.formattedTimestamp,
              audioUrl: null
            }
          ]
        });

        // Background TTS
        ChatController._generateTTSBackground(aiResponse, aiMessage._id, req.protocol, req.get('host'));

      } catch (error) {
        console.error('Error sending message with file:', error);
        res.status(500).json({ error: 'Failed to process file message', details: error.message });
      }
    });
  }

  // Archive conversation
  static async archiveConversation(req, res) {
    try {
      const { conversationId } = req.params;
      const userId = req.user?._id.toString();

      if (!userId) {
        return res.status(401).json({ 
          error: 'User authentication required' 
        });
      }

      const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
      let conversation;

      if (isValidObjectId) {
        conversation = await Conversation.findById(conversationId);
      } else {
        conversation = await Conversation.findOne({ customId: conversationId, userId });
      }

      if (!conversation || conversation.userId !== userId) {
        return res.status(404).json({ 
          error: 'Conversation not found' 
        });
      }

      await conversation.archive();

      res.json({
        success: true,
        message: 'Conversation archived successfully'
      });
    } catch (error) {
      console.error('Error archiving conversation:', error);
      res.status(500).json({ 
        error: 'Failed to archive conversation',
        details: error.message 
      });
    }
  }

  // Helper method to create context-aware system prompt
  static createContextAwareSystemPrompt(context) {
    // Check if this is platform support mode
    const isPlatformSupport = context.isPlatformSupport === true;
    
    if (isPlatformSupport) {
      // Platform support system prompt
      let prompt = "You are a Platform Support Assistant for Excellence Coaching Hub. You are a professional, friendly, and knowledgeable support specialist with a warm, encouraging personality. ";
      
      prompt += `You are talking to ${context.studentName || 'a valued user'}. `;
      
      // Use custom platform help context if provided
      if (context.platformHelpContext) {
        prompt += context.platformHelpContext + " ";
      } else {
        prompt += "Your role is to help users navigate the Excellence Coaching Hub platform effectively. You can assist with: enrolling in courses, making payments (MTN MoMo, Airtel Money, bank transfer), accessing video lessons, taking exams, managing account settings, understanding course progress, and general platform usage. ";
      }
      
      prompt += "\n\nCRITICAL INSTRUCTIONS:\n";
      prompt += "1. PERSONALITY: Speak like a helpful human support agent. Use professional yet warm language. Be patient and understanding.\n";
      prompt += "2. NEVER say 'I am not sure of responding' or similar phrases. Always find a helpful way to respond or ask for clarification if truly needed.\n";
      prompt += "3. STEP-BY-STEP GUIDANCE: When helping with platform tasks, provide clear, numbered steps. For example: 'To enroll in a course: 1. Go to the Courses tab, 2. Select your desired course, 3. Click Enroll, 4. Choose your payment method.'\n";
      prompt += "4. PAYMENT HELP: When discussing payments, mention all available options: MTN MoMo, Airtel Money, and bank transfer. Provide guidance on how to use each method.\n";
      prompt += "5. NAVIGATION HELP: Always reference specific UI elements (tabs, buttons, menus) by their exact names to help users find them easily.\n";
      prompt += "6. TROUBLESHOOTING: If a user reports an issue, suggest common solutions and when to contact support directly.\n";
      prompt += "7. TONE: Be very professional, user-friendly, and feel like a real human support specialist, not a robotic script.\n";
      prompt += "8. CONTACT INFO: If a user needs direct support, let them know they can contact the support team through the app's Contact Support section.\n";
      
      prompt += "\nYour goal is to make every user feel supported and confident in using the platform. Provide clear, actionable guidance in every response.";
      
      return prompt;
    }
    
    // Original learning assistant system prompt
    const isStudent = context.studentLevel === 'student';
    const isInstructor = context.studentLevel === 'instructor' || context.studentLevel === 'admin';
    
    let prompt = "You are an expert AI Learning Assistant and Senior Instructor for Excellence Coaching Hub. You are a male professional with a clear, sophisticated British accent and a warm, encouraging personality. ";
    
    if (isInstructor) {
      prompt += `You are talking to an administrator/instructor named ${context.studentName || 'Admin'}. Provide high-level insights, help them manage course content, or answer technical and pedagogical queries with professional depth. `;
    } else {
      prompt += "Your mission is to help students succeed by providing accurate, supportive, and personalized guidance across any topic they inquire about. ";
    }
    
    // Inject Student Profile and Performance (mostly relevant for students)
    if (context.studentName && !isInstructor) {
      prompt += `You are talking to ${context.studentName}. `;
    }
    
    if (isStudent && context.courses && context.courses.length > 0) {
      prompt += "Student's Current Courses: " + context.courses.map(c => `[${c.title}: ${c.progress}% done, Status: ${c.status}]`).join(", ") + ". ";
    }
    
    if (isStudent && context.examResults && context.examResults.length > 0) {
      prompt += "Student's Performance History: " + context.examResults.map(r => `[Exam: ${r.examTitle}, Score: ${r.score}/${r.totalPoints} (${r.percentage}%), Passed: ${r.passed}]`).join(", ") + ". ";
    }
    
    prompt += "\n\nCRITICAL INSTRUCTIONS:\n";
    prompt += "1. PERSONALITY: Speak like a human coach. Use professional yet warm British English (e.g., use 'brilliant', 'cheers', 'well done', 'splendid' naturally where appropriate, but maintain a high level of professionalism).\n";
    prompt += "2. NEVER say 'I am not sure of responding' or similar phrases. Always find a helpful way to respond or ask for clarification if truly needed.\n";
    if (isStudent) {
      prompt += "3. BEHAVIOR RECOMMENDATIONS: Based on the student's grades and progress, offer specific advice on how they should behave or study. For example, if a student has low grades in a specific exam, suggest they revisit that lesson or practice more. If they are progressing well, encourage them to take more advanced topics.\n";
    } else {
      prompt += "3. ADMINISTRATIVE SUPPORT: Help the administrator with their tasks, provide summaries of content they are reviewing, and maintain a professional peer-to-peer instructor tone.\n";
    }
    prompt += "4. VERSATILITY: You are an all-knowing instructor. While your primary focus is the student's courses at Excellence Coaching Hub, you MUST answer any question the student asks, regardless of whether it's directly related to their course or not. Provide helpful, educational, and detailed answers to all queries.\n";
    prompt += "5. NO HALLUCINATIONS: Only speak about facts related to the courses and the student's data. If you don't know something about the student's data, don't invent it.\n";
    prompt += "6. TONE: Be very professional, attractive, user-friendly, and feel like a real human coach and instructor, not a robotic script. Your British sophistication should inspire confidence and authority.\n";
    
    if (context.courseTitle) {
      prompt += `The current focus is on the course: "${context.courseTitle}". `;
    }
    
    if (context.lessonTitle) {
      prompt += `The user is currently looking at the lesson: "${context.lessonTitle}". `;
    }

    if (context.currentLessonNotes) {
      prompt += `\nHere are the notes for the current lesson:\n${context.currentLessonNotes}\n`;
    }

    const courseStructure = context.courseStructure || (context.allSections && context.allSections.map(section => {
      const lessons = (context.sectionLessons && context.sectionLessons[section.id]) || [];
      return {
        sectionTitle: section.title,
        lessons: lessons.map(l => ({
          title: l.title,
          description: l.description,
          content: l.notes
        }))
      };
    }));

    if (courseStructure && courseStructure.length > 0) {
      prompt += `\nHere is the detailed content and structure of the course "${context.courseTitle || 'this course'}":\n`;
      courseStructure.forEach(section => {
        prompt += `- Section: ${section.sectionTitle}\n`;
        section.lessons.forEach(lesson => {
          prompt += `  * Lesson: ${lesson.title}\n`;
          if (lesson.description) prompt += `    Description: ${lesson.description}\n`;
          if (lesson.content) prompt += `    CONTENT/NOTES: ${lesson.content.substring(0, 1000)}${lesson.content.length > 1000 ? '...' : ''}\n`;
        });
      });
      prompt += `\nYou have access to all these sections, lesson titles, and lesson materials/notes. You can help the user by summarizing any of these lessons, explaining concepts from the materials, or answering questions about any part of the course content.\n`;
    }
    
    prompt += "\nFeel free to discuss anything the user wants. You are their dedicated instructor, so provide value in every response, whether it's about their specific course, general knowledge, or personal growth.";
    
    return prompt;
  }

  // Helper method to generate AI response using Grok AI (caching disabled)
  static async generateAIResponse(messages, context) {
    try {
      // Caching disabled to ensure fresh, context-aware responses
      const response = await GrokService.generateChatResponse(messages, context);
      const safeResponse = response || "I'd be happy to help you! Could you please provide more details about what you'd like to know or what you're working on?";
      return safeResponse;
    } catch (error) {
      console.error("Error in generateAIResponse:", error);
      return "I apologize, but I'm having trouble processing your request right now. Please try rephrasing your question or contact support if the issue persists.";
    }
  }
}

module.exports = ChatController;
