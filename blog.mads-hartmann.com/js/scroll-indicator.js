//
// This is a modified version of the following project on Github.
// https://github.com/alssndro/page-scroll-indicator
//

var progressBarElement = document.getElementsByClassName(
  'scroll-indicator-progress'
).item(0);

var contentContainer = document.getElementsByClassName('post').item(0);

if (progressBarElement && contentContainer) {
  progressBarElement.style.width = "0%";

  window.onscroll = function(event) {
    // We're interested in showing the progress of the element that contains
    // the actual content. In my case that's the div.post element.

    var pageHeight = window.innerHeight;
    var adjustedHeight = contentContainer.offsetTop + contentContainer.clientHeight - pageHeight;
    var progress = window.pageYOffset / adjustedHeight * 100;

    progressBarElement.style.width = progress + "%";
  };
}
