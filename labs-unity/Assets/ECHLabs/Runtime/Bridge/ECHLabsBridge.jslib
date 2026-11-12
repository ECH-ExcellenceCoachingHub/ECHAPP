// WebGL ↔ host page (Flutter web iframe). Messages go to window.parent with origin checks done by the host.
mergeInto(LibraryManager.library, {
  ECHLabs_GetFragment: function () {
    var s = (window.location.hash || '').replace(/^#/, '');
    var size = lengthBytesUTF8(s) + 1;
    var buf = _malloc(size);
    stringToUTF8(s, buf, size);
    return buf;
  },
  ECHLabs_ClearFragment: function () {
    try { history.replaceState(null, '', window.location.pathname + window.location.search); } catch (e) {}
  },
  ECHLabs_PostToHost: function (jsonPtr) {
    var json = UTF8ToString(jsonPtr);
    try {
      var msg = JSON.parse(json);
      msg.source = 'ech-labs';
      if (window.parent && window.parent !== window) window.parent.postMessage(msg, '*');
      window.dispatchEvent(new CustomEvent('ech-labs', { detail: msg }));
    } catch (e) { console.warn('[ECHLabs] postMessage failed', e); }
  }
});
