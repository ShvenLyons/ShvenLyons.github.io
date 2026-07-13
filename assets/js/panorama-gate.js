(function (window, document) {
  "use strict";

  var root = document.documentElement;

  function denyAccess() {
    window.location.replace("/");
  }

  async function requestAccess() {
    try {
      if (window.siteAccess && await window.siteAccess.request({
        cancelLabel: "Return home",
        singleAttempt: true
      })) {
        root.classList.remove("access-pending");
        return;
      }
    } catch (error) {
      denyAccess();
      return;
    }

    denyAccess();
  }

  requestAccess();
}(window, document));
