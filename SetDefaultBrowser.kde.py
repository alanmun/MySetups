#!/usr/bin/python3 -I
"""Open a link in the browser you used last (KDE Plasma 6 port of SetDefaultBrowser.ahk).

Registered as the system default browser. When another app opens a link, this
asks KWin which browser window is highest in the window stack, which is the one
focused most recently, and hands the link to that browser. If no browser window
is open, the first entry in BROWSERS is used.

  SetDefaultBrowser.kde.py <url>...     open the links
  SetDefaultBrowser.kde.py --which      print the browser that would be used
  SetDefaultBrowser.kde.py --install    register as the default browser
  SetDefaultBrowser.kde.py --remove     unregister and restore Firefox
"""

import os
import subprocess
import sys
import tempfile

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

# (window class substring, command). Order is the fallback order when no
# browser window is open. Add profile flags here if a machine needs them,
# for example ["google-chrome-stable", "--profile-directory=Profile 2"].
BROWSERS = [
    ("firefox", ["firefox"]),
    ("google-chrome", ["google-chrome-stable", "--enable-blink-features=MiddleClickAutoscroll"]),
]

DESKTOP_ID = "set-default-browser.desktop"
DESKTOP_PATH = os.path.join(
    os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")),
    "applications",
    DESKTOP_ID,
)
FALLBACK_DESKTOP_ID = "org.mozilla.firefox.desktop"
IFACE = "org.mysetups.BrowserPick"
PATH = "/BrowserPick"
PLUGIN = "mysetups-browser-pick"

KWIN_SCRIPT = """
var needles = %(needles)s;
var order = workspace.stackingOrder;
var hit = "";
for (var i = order.length - 1; i >= 0 && hit === ""; i--) {
    var w = order[i];
    if (!w.normalWindow) continue;
    var cls = String(w.resourceClass).toLowerCase();
    for (var j = 0; j < needles.length; j++) {
        if (cls.indexOf(needles[j]) !== -1) { hit = needles[j]; break; }
    }
}
callDBus("%(dest)s", "%(path)s", "%(iface)s", "Picked", hit);
"""


def last_used_browser(timeout_ms=1500):
    """Window-class needle of the most recently focused browser, or '' if none."""
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    loop = GLib.MainLoop()
    result = {"needle": ""}

    def on_call(_conn, _sender, _path, _iface, _method, params, invocation):
        result["needle"] = params.unpack()[0]
        invocation.return_value(None)
        loop.quit()

    node = Gio.DBusNodeInfo.new_for_xml(
        f'<node><interface name="{IFACE}"><method name="Picked">'
        '<arg type="s" direction="in"/></method></interface></node>'
    )
    reg = bus.register_object(PATH, node.interfaces[0], on_call, None, None)

    script = KWIN_SCRIPT % {
        "needles": repr([needle for needle, _cmd in BROWSERS]),
        "dest": bus.get_unique_name(),
        "path": PATH,
        "iface": IFACE,
    }
    with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as handle:
        handle.write(script)
        script_path = handle.name

    def kwin(method, args, path="/Scripting", iface="org.kde.kwin.Scripting"):
        return bus.call_sync("org.kde.KWin", path, iface, method, args, None,
                             Gio.DBusCallFlags.NONE, 1000, None)

    try:
        kwin("unloadScript", GLib.Variant("(s)", (PLUGIN,)))
        script_id = kwin("loadScript", GLib.Variant("(ss)", (script_path, PLUGIN))).unpack()[0]
        kwin("run", None, f"/Scripting/Script{script_id}", "org.kde.kwin.Script")
        GLib.timeout_add(timeout_ms, loop.quit)
        loop.run()
    except GLib.Error:
        pass  # not a KDE session, or KWin did not answer: use the fallback
    finally:
        try:
            kwin("unloadScript", GLib.Variant("(s)", (PLUGIN,)))
        except GLib.Error:
            pass
        bus.unregister_object(reg)
        os.unlink(script_path)
    return result["needle"]


def pick():
    needle = last_used_browser()
    for candidate, command in BROWSERS:
        if candidate == needle:
            return command
    return BROWSERS[0][1]


def install():
    os.makedirs(os.path.dirname(DESKTOP_PATH), exist_ok=True)
    with open(DESKTOP_PATH, "w") as handle:
        handle.write(
            "[Desktop Entry]\n"
            "Type=Application\n"
            "Name=Last Used Browser\n"
            "Comment=Opens links in the browser you focused most recently\n"
            f"Exec={os.path.realpath(__file__)} %U\n"
            "Icon=internet-web-browser\n"
            "Categories=Network;WebBrowser;\n"
            "MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;\n"
            "NoDisplay=true\n"
        )
    subprocess.run(["update-desktop-database", os.path.dirname(DESKTOP_PATH)], check=False)
    subprocess.run(["xdg-settings", "set", "default-web-browser", DESKTOP_ID], check=True)
    print(f"Default browser is now {DESKTOP_ID}")


def remove():
    subprocess.run(["xdg-settings", "set", "default-web-browser", FALLBACK_DESKTOP_ID], check=True)
    if os.path.exists(DESKTOP_PATH):
        os.unlink(DESKTOP_PATH)
    print(f"Default browser is now {FALLBACK_DESKTOP_ID}")


def main(argv):
    if argv == ["--install"]:
        return install()
    if argv == ["--remove"]:
        return remove()
    if argv == ["--which"]:
        print(" ".join(pick()))
        return None
    if not argv or argv[0].startswith("--"):
        print(__doc__)
        return None
    command = pick()
    os.execvp(command[0], command + argv)


if __name__ == "__main__":
    main(sys.argv[1:])
