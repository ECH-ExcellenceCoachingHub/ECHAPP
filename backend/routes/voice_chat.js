const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Groq = require('groq-sdk');
const { spawn } = require('child_process');
const router = express.Router();

// Set up multer for audio file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/voice';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'voice-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    // Accept only audio files
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed'));
    }
  }
});

// In-memory storage for conversations (same as ai_chat)
const conversations = new Map();

// Initialize the AI clients
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY || 'your-google-api-key-here');
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || 'your-groq-api-key-here' });

const Section = require('../src/models/Section');
const Lesson = require('../src/models/Lesson');
const Course = require('../src/models/Course');
const ChatController = require('../src/controllers/chat.controller');
const TTSService = require('../src/services/tts.service');

// Voice transcription using Whisper-like model via Groq API
async function transcribeAudio(audioFilePath) {
  try {
    const transcription = await groq.audio.transcriptions.create({
      file: fs.createReadStream(audioFilePath),
      model: "whisper-large-v3-turbo", // Use turbo for speed
      response_format: "json",
      language: "en",
    });
    return transcription.text;
  } catch (error) {
    console.error('Transcription error:', error);
    throw error;
  }
}

/**
 * Text-to-Speech using ElevenLabs, same voice as video narration
 */
async function speechFileFor(text) {
  try {
    return await TTSService.speechFileFor(text);
  } catch (error) {
    console.error('TTS error:', error);
    return null;
  }
}

// Endpoint to handle voice message
router.post('/send', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    let { conversationId, context } = req.body;
    
    // context might be stringified if sent via multipart/form-data
    if (typeof context === 'string') {
      try {
        context = JSON.parse(context);
      } catch (e) {
        console.error('Error parsing context:', e);
      }
    }

    // Transcribe the audio to text
    const transcribedText = await transcribeAudio(req.file.path);
    
    // Prepare enriched context
    const enrichedContext = context || {};

    // Get or create conversation (using DB if possible)
    const Conversation = require('../src/models/Conversation');
    const userId = req.user?._id?.toString();
    let conversation;

    if (conversationId && !conversationId.startsWith('conversation_')) {
      const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
      if (isValidObjectId) {
        conversation = await Conversation.findById(conversationId);
      } else {
        conversation = await Conversation.findOne({ customId: conversationId, userId });
        if (!conversation) {
          conversation = await Conversation.getOrCreateConversation(userId, { customId: conversationId, ...enrichedContext });
        }
      }
    } else if (userId) {
      conversation = await Conversation.getOrCreateConversation(userId, { customId: 'support_chat' });
    }
    
    // Generate AI response using ChatController logic for consistency
    const messagesForAI = [
      {
        role: 'system',
        content: ChatController.createContextAwareSystemPrompt(enrichedContext)
      },
      {
        role: 'user',
        content: transcribedText
      }
    ];
    
    const aiResponse = await ChatController.generateAIResponse(messagesForAI, enrichedContext);
    
    // Generate audio response (cached by text, shared with POST /api/ai/tts)
    const audioFileName = await speechFileFor(aiResponse);

    // Construct full URL for audio response
    const protocol = (req.get('x-forwarded-proto') || req.protocol).split(',')[0].trim();
    const host = req.get('host');
    const audioUrl = audioFileName ? `${protocol}://${host}/uploads/voice/${audioFileName}` : null;
    
    res.json({
      textResponse: aiResponse,
      audioResponse: audioUrl,
      transcribedText: transcribedText,
      conversationId: conversationId
    });
  } catch (error) {
    console.error('Error processing voice message:', error);
    res.status(500).json({ 
      error: 'Failed to process voice message', 
      message: 'I\'m sorry, I hit a snag while trying to process your voice message.'
    });
  }
});

// Alternative endpoint for real-time voice processing (streaming)
router.post('/voice/stream', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    const { conversationId, context } = req.body;
    
    // Transcribe the audio to text
    const transcribedText = await transcribeAudio(req.file.path);
    
    // Get or create conversation
    let conversation = conversations.get(conversationId);
    if (!conversation) {
      const { v4: uuidv4 } = require('uuid');
      const newConversationId = uuidv4();
      conversation = {
        id: newConversationId,
        context: context || {},
        messages: [],
        createdAt: new Date()
      };
      conversations.set(newConversationId, conversation);
    }
    
    // Add user's transcribed message to conversation
    const userMessage = {
      id: `user_${Date.now()}`,
      sender: 'user',
      message: transcribedText,
      originalAudio: req.file.path,
      timestamp: new Date(),
      isContextAware: false
    };
    
    conversation.messages.push(userMessage);
    
    // Prepare messages for AI
    const messagesForAI = [
      {
        role: 'system',
        content: createContextAwareSystemPrompt(conversation.context)
      },
      ...conversation.messages.slice(-10).map(msg => ({
        role: msg.sender === 'user' ? 'user' : 'assistant',
        content: msg.message
      }))
    ];
    
    // Create a streaming response
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Transfer-Encoding', 'chunked');
    
    // Use Groq streaming for real-time response
    const chatStream = await groq.chat.completions.create({
      messages: messagesForAI,
      model: "mixtral-8x7b-32768",
      temperature: 0.7,
      max_tokens: 1024,
      top_p: 1,
      stream: true
    });
    
    let fullResponse = '';
    for await (const chunk of chatStream) {
      const content = chunk.choices[0]?.delta?.content || '';
      fullResponse += content;
      res.write(content);
    }
    
    // Add AI response to conversation
    const aiMessage = {
      id: `ai_${Date.now()}`,
      sender: 'ai',
      message: fullResponse,
      timestamp: new Date(),
      isContextAware: true
    };
    
    conversation.messages.push(aiMessage);
    
    res.end();
  } catch (error) {
    console.error('Error processing voice stream:', error);
    res.status(500).json({ 
      error: 'Failed to process voice stream' 
    });
  }
});

// Endpoint to get voice response as audio
router.get('/voice/response/:conversationId/:messageId', (req, res) => {
  try {
    const { conversationId, messageId } = req.params;
    const conversation = conversations.get(conversationId);
    
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    // Find the message with audio
    const message = conversation.messages.find(msg => msg.id === messageId);
    if (!message || !message.audioUrl) {
      return res.status(404).json({ error: 'Audio response not found' });
    }
    
    // Serve the audio file
    const filePath = path.join(__dirname, '../', message.audioUrl);
    res.sendFile(filePath);
  } catch (error) {
    console.error('Error serving audio:', error);
    res.status(500).json({ error: 'Failed to serve audio' });
  }
});

// Helper function to create context-aware system prompt
function createContextAwareSystemPrompt(context) {
  let prompt = "You are an expert AI Learning Assistant and Senior Instructor for Excellence Coaching Hub. You are a male professional with a clear, sophisticated British accent and a warm, encouraging personality. Your mission is to help students succeed by providing accurate, supportive, and personalized guidance across any topic they inquire about. Speak like a human coach. Use professional yet warm British English (e.g., use 'brilliant', 'cheers', 'well done', 'splendid' naturally where appropriate, but maintain a high level of professionalism). ";
  
  if (context.courseTitle) {
    prompt += `The student is studying "${context.courseTitle}". `;
  }
  
  if (context.lessonTitle) {
    prompt += `They are currently working on "${context.lessonTitle}". `;
  }
  
  if (context.studentName) {
    prompt += `The student's name is ${context.studentName}. `;
  }
  
  if (context.studentLevel) {
    prompt += `Their current level is ${context.studentLevel}. `;
  }
  
  prompt += `Provide helpful, educational responses that relate to their current learning context. `;
  prompt += `Keep your responses informative, encouraging, and tailored to their specific learning situation. `;
  prompt += `If they're struggling with a concept, offer to break it down into simpler parts. `;
  prompt += `If they're asking for practice, suggest relevant exercises. `;
  prompt += `Always maintain a supportive and educational tone. Your British sophistication should inspire confidence and authority.`;
  
  return prompt;
}

module.exports = router;