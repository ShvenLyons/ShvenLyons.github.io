(function () {
  "use strict";

  var widgetUrl = "https://mapmyvisitors.com/map.js?cl=5568c1&w=500&t=m&d=W3Jkh14-NItxXnpyT3N4p0RoBPB-KHGIfRn1fa7YYz4&co=94bcd8&ct=2dba6c&cmo=cbedf7&cmn=e02247";

  function loadVisitorTracker() {
    // The 404 page already contains the visible widget, which also records the visit.
    if (document.getElementById("mapmyvisitors")) return;

    var container = document.createElement("div");
    var script = document.createElement("script");

    container.hidden = true;
    container.setAttribute("aria-hidden", "true");

    script.id = "mapmyvisitors";
    script.src = widgetUrl;
    script.async = true;

    container.appendChild(script);
    document.body.appendChild(container);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", loadVisitorTracker, { once: true });
  } else {
    loadVisitorTracker();
  }
}());
