const express = require('express');
const router = express.Router();
const ChatController = require('../src/controllers/chat.controller');
const { protect } = require('../src/middleware/auth.middleware');

// Endpoint to get user's conversations
router.get('/conversations', protect, ChatController.getUserConversations);

// Endpoint to get specific conversation messages
router.get('/conversations/:conversationId', protect, ChatController.getConversationMessages);

// Endpoint to create a new conversation
router.post('/conversations/create', protect, ChatController.createConversation);

// Endpoint to archive conversation
router.delete('/conversations/:conversationId', protect, ChatController.archiveConversation);

// Endpoint to send a message and get AI response
router.post('/chat/send', protect, ChatController.sendMessage);

// Endpoint to send a message with a file attachment (document/image)
router.post('/chat/send-with-file', protect, ChatController.sendMessageWithFile);

// Endpoint to turn assistant text into speech (ElevenLabs, same voice as videos)
router.post('/tts', protect, ChatController.synthesizeSpeech);

// Endpoint to update conversation context
router.put('/conversations/:conversationId/context', protect, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { context } = req.body;
    const userId = req.user?.uid || req.user?._id;

    if (!userId) {
      return res.status(401).json({ error: 'User authentication required' });
    }

    const Conversation = require('../src/models/Conversation');
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(conversationId);
    let conversation;

    if (isValidObjectId) {
      conversation = await Conversation.findById(conversationId);
    } else {
      conversation = await Conversation.findOne({ customId: conversationId, userId });
    }

    if (!conversation || conversation.userId !== userId) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Update conversation context
    if (context.courseId) conversation.courseId = context.courseId;
    if (context.lessonId) conversation.lessonId = context.lessonId;
    if (context.sectionTitle) conversation.sectionTitle = context.sectionTitle;
    if (context.studentLevel) conversation.studentLevel = context.studentLevel;

    await conversation.save();

    res.json({
      success: true,
      message: 'Context updated successfully'
    });
  } catch (error) {
    console.error('Error updating context:', error);
    res.status(500).json({ error: 'Failed to update context' });
  }
});

module.exports = router;