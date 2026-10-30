const mongoose = require('mongoose');

/**
 * A real experiment demonstration on YouTube, chosen by the teacher for a
 * science lesson (Lesson.demo / CourseBuildItem.demo). The video is never
 * copied: students watch it in YouTube's own embedded player while the app
 * shows the lesson's steps beside it and pauses at each step for a short
 * explanation and an optional check question.
 *
 * Missing / null on older documents = no demonstration.
 */

const videoSchema = new mongoose.Schema({
  videoId: { type: String, required: true },
  title: String,
  channel: String,
  durationSec: Number,
  thumbnail: String,
  // Chapters from the video description ("0:00 Intro"), used to place steps.
  chapters: { type: [{ _id: false, at: Number, title: String }], default: [] },
}, { _id: false });

const stepSchema = new mongoose.Schema({
  text: { type: String, required: true },
  // Second in the video where this step is shown; null until it is placed.
  at: { type: Number, default: null },
  // How `at` was set: matched to a chapter, or marked by the teacher.
  source: { type: String, enum: ['chapter', 'teacher', null], default: null },
  // What the narrator says when the video pauses at the end of this step.
  explain: { type: String, default: '' },
  check: {
    type: new mongoose.Schema({
      question: String,
      choices: [String],
      answerIndex: Number,
      explanation: String,
    }, { _id: false }),
    default: null,
  },
}, { _id: false });

const demoSchema = new mongoose.Schema({
  query: String,
  suggestions: { type: [videoSchema], default: [] },
  searchedAt: Date,
  selected: { type: videoSchema, default: null },
  steps: { type: [stepSchema], default: [] },
  updatedAt: Date,
}, { _id: false });

module.exports = { demoSchema };
