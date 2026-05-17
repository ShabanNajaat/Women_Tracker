(function () {
  var forced = localStorage.getItem('glow_dark_mode');
  if (forced === 'true') {
    document.documentElement.setAttribute('data-theme', 'dark');
  } else if (forced === 'false') {
    document.documentElement.setAttribute('data-theme', 'light');
  } else {
    document.documentElement.removeAttribute('data-theme');
  }
})();
