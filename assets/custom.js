// Custom JavaScript for INECOBANK Superset
// Sets the browser tab title

(function() {
    const brandName = 'INECOBANK Growth Marketing';
    
    // Set initial title
    if (!document.title || document.title.trim() === '') {
        document.title = brandName;
    }
    
    // Observer to update title if React changes it
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList' && mutation.target === document.querySelector('head')) {
                const titleElement = document.querySelector('title');
                if (titleElement && (!titleElement.textContent || titleElement.textContent.trim() === '')) {
                    titleElement.textContent = brandName;
                }
            }
        });
    });
    
    // Observe head for title changes
    if (document.head) {
        observer.observe(document.head, { childList: true, subtree: true });
    }
    
    // Also set on DOMContentLoaded and load
    document.addEventListener('DOMContentLoaded', function() {
        if (!document.title || document.title.trim() === '') {
            document.title = brandName;
        }
    });
    
    window.addEventListener('load', function() {
        if (!document.title || document.title.trim() === '') {
            document.title = brandName;
        }
    });
})();
