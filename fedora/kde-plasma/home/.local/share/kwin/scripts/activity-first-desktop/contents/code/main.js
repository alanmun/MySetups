// Each time one of these Activities becomes active, go to the leftmost desktop.
// The ID is from: qdbus org.kde.ActivityManager /ActivityManager/Activities ListActivities
var activities = ["4f6db3c2-d145-4c34-bb7d-97326e79a291"]; // Scratch

workspace.currentActivityChanged.connect(function () {
    if (activities.indexOf(String(workspace.currentActivity)) !== -1) {
        workspace.currentDesktop = workspace.desktops[0];
    }
});
