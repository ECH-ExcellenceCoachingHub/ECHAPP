mergeInto(LibraryManager.library, {
  ECHLabs_Speak: function (textPtr, langPtr) {
    try {
      if (!window.speechSynthesis) return;
      var text = UTF8ToString(textPtr), lang = UTF8ToString(langPtr);
      window.speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(text);
      u.lang = lang;
      u.rate = 1.0;
      var voices = window.speechSynthesis.getVoices() || [];
      var v = voices.find(function (x) { return x.lang && x.lang.toLowerCase().indexOf(lang.substring(0, 2).toLowerCase()) === 0; });
      if (!v && lang.indexOf('rw') === 0) return; // no Kinyarwanda voice: subtitles only
      if (v) u.voice = v;
      window.speechSynthesis.speak(u);
    } catch (e) {}
  },
  ECHLabs_StopSpeaking: function () { try { window.speechSynthesis && window.speechSynthesis.cancel(); } catch (e) {} }
});
