// Stellt die festen Nummern (data-z) in eine Randspalte links vom Text.
// Die Nummern selbst stammen aus review-zeilennummern.lua und ändern sich nicht.
(function () {
  var main = document.querySelector("main");
  var marken = Array.prototype.slice.call(document.querySelectorAll("[data-z]"));
  if (!main || !marken.length) return;

  document.body.classList.add("zn-js");
  var rinne = document.createElement("div");
  rinne.id = "zn-rinne";
  var linie = document.createElement("div");
  linie.className = "zn-linie";
  rinne.appendChild(linie);
  document.body.appendChild(rinne);

  var labels = marken.map(function (m) {
    var a = document.createElement("a");
    a.className = "zn-nr";
    a.href = "#z" + m.dataset.z;
    a.textContent = m.dataset.z;
    a.title = "Direktlink auf Z. " + m.dataset.z;
    rinne.appendChild(a);
    return a;
  });

  function setzen() {
    var rem = parseFloat(getComputedStyle(document.documentElement).fontSize);
    main.style.paddingLeft = "";
    if (main.getBoundingClientRect().left < 4 * rem) main.style.paddingLeft = "3.4rem";
    var mr = main.getBoundingClientRect();
    var links = mr.left + window.scrollX - 3.6 * rem;
    marken.forEach(function (m, i) {
      var l = labels[i];
      var r = m.getBoundingClientRect();
      // In Flex-Containern hat die leere Marke keine Grösse: Elternelement nehmen
      if (!r.height && !r.width && m.parentElement) r = m.parentElement.getBoundingClientRect();
      if (!r.height && !r.width) { l.hidden = true; return; }
      l.hidden = false;
      var oben = r.top + window.scrollY;
      if (m.tagName === "SPAN") oben += (r.height - l.offsetHeight) / 2;
      l.style.top = oben + "px";
      l.style.left = links + "px";
    });
    linie.style.left = links + 2.9 * rem + "px";
    linie.style.top = mr.top + window.scrollY + "px";
    linie.style.height = mr.height + "px";
  }

  function markieren() {
    document.querySelectorAll(".zn-ziel").forEach(function (e) { e.classList.remove("zn-ziel"); });
    labels.forEach(function (l) { l.classList.remove("zn-aktiv"); });
    var m = /^#z(\d+)$/.exec(location.hash);
    if (!m) return;
    var el = document.getElementById("z" + m[1]);
    if (!el) return;
    var block = el.tagName === "SPAN" ? el.closest("h1,h2,h3,h4,p,li,tr,div") : el;
    if (block) block.classList.add("zn-ziel");
    labels[marken.indexOf(el)].classList.add("zn-aktiv");
  }

  setzen();
  markieren();
  window.addEventListener("load", setzen);
  window.addEventListener("resize", setzen);
  window.addEventListener("hashchange", markieren);
  if (document.fonts) document.fonts.ready.then(setzen);
  if (window.ResizeObserver) new ResizeObserver(setzen).observe(main);
})();
