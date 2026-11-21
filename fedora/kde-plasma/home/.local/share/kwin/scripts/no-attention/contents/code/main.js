// When a window sets the "demands attention" state:
//  - a web browser is shown and focused (a link was opened in it),
//  - all other windows have the state cleared, so the taskbar does not flash.
var focusClasses = ["firefox", "org.mozilla.firefox", "google-chrome", "chromium-browser",
                    "brave-browser", "microsoft-edge", "vivaldi-stable", "librewolf", "zen"];

function handle(w) {
    if (!w.demandsAttention) {
        return;
    }
    var cls = String(w.resourceClass).toLowerCase();
    if (focusClasses.indexOf(cls) !== -1) {
        w.minimized = false;
        workspace.activeWindow = w;
    }
    w.demandsAttention = false;
}

function watch(w) {
    w.demandsAttentionChanged.connect(function () { handle(w); });
    handle(w);
}
workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
