// Custom JavaScript for INECOBANK Superset
// Sets the browser tab title

(function() {
    var brandName = 'INECOBANK Growth Marketing';
    
    function setCorrectTitle() {
        var t = document.title || '';
        if (!t.trim() || t.includes('localhost') || t === 'Superset') {
            document.title = brandName;
        }
    }
    
    setCorrectTitle();
    
    // Override whenever title changes (React overwrites it)
    var titleEl = document.querySelector('title');
    if (titleEl) {
        var observer = new MutationObserver(setCorrectTitle);
        observer.observe(titleEl, { childList: true, characterData: true, subtree: true });
    }
    
    // Also poll as fallback
    setInterval(setCorrectTitle, 500);
})();
