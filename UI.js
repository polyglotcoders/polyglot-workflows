function ReplaceWithPolyfill() {
  'use-strict'; // For safari, and IE > 10
  var parent = this.parentNode, i = arguments.length, currentNode;
  if (!parent) return;
  if (!i) // if there are no arguments
    parent.removeChild(this);
  while (i--) { // i-- decrements i and returns the value of i before the decrement
    currentNode = arguments[i];
    if (typeof currentNode !== 'object'){
      currentNode = this.ownerDocument.createTextNode(currentNode);
    } else if (currentNode.parentNode){
      currentNode.parentNode.removeChild(currentNode);
    }
    // the value of "i" below is after the decrement
    if (!i) // if currentNode is the first argument (currentNode === arguments[0])
      parent.replaceChild(currentNode, this);
    else // if currentNode isn't the first
      parent.insertBefore(this.previousSibling, currentNode);
  }
}
if (!Element.prototype.replaceWith)
    Element.prototype.replaceWith = ReplaceWithPolyfill;
if (!CharacterData.prototype.replaceWith)
    CharacterData.prototype.replaceWith = ReplaceWithPolyfill;
if (!DocumentType.prototype.replaceWith) 
    DocumentType.prototype.replaceWith = ReplaceWithPolyfill;


window.scrollTo = function(element, to, duration) {
  var start = element.scrollTop,
      change = to - start,
      currentTime = 0,
      increment = 20;
      
  var animateScroll = function(){
      currentTime += increment;
      var val = Math.easeInOutQuad(currentTime, start, change, duration);
      element.scrollTop = val;
      if(currentTime < duration) {
        setTimeout(animateScroll, increment);
      }
  };
  animateScroll();
}

//t = current time
//b = start value
//c = change in value
//d = duration
Math.easeInOutQuad = function (t, b, c, d) {
  t /= d/2;
  if (t < 1) return c/2*t*t + b;
  t--;
  return -c/2 * (t*(t-2) - 1) + b;
};

var scrollToActiveNavItem = function() {
  var nav = document.querySelector('#index nav');

  nav.focus();
  scrollTo(
    document.querySelector('.layout'),
    document.querySelector('nav .active').offsetTop,
    550
  );
};


document.addEventListener('DOMContentLoaded', function() {
  var fallbackCopyTextToClipboard = function(text, callback) {
    var textarea = document.createElement('textarea');
    document.body.appendChild(textarea);
    textarea.value = text;
    textarea.focus();
    textarea.select();
 
    try {
      document.execCommand('copy');
      callback();
    } catch (err) {
      console.error('Oops, unable to copy', err);
    }

    document.body.removeChild(textarea);
  };

  var copyTextToClipboard = function(text, callback) {
    if (!navigator.clipboard) {
      fallbackCopyTextToClipboard(text, callback);
      return;
    }
    navigator.clipboard.writeText(text).then(
      function() { callback(); },
      function(err) {
        console.error('Oops, unable to copy', err);
      }
    );
  };

  // mobile nav "menu" button
  document
    .querySelector('.link-menu')
    .addEventListener('click', function(e) {
      var nav = document.querySelector('#index nav');
      nav.classList.toggle('open');

      if(nav.classList.contains('open')) {
        setTimeout(scrollToActiveNavItem, 200);
      }
    });

  // wrap terminal commands in div.instructions
  document.querySelectorAll('.instructions').forEach(function(pre, i) {
    var lines = pre.innerHTML.split('\n');
    var container = document.createElement('div');
    container.classList.add('instructions');

    lines.forEach(function(line, i) {
      var pre = document.createElement('pre');
      pre.innerHTML = line;
      container.appendChild(pre);
    });

    pre.replaceWith(container);
  });

  // copy terminal command to clipboard
  document
    .querySelectorAll('.instructions pre')
    .forEach(function(i) {
      i.setAttribute('tabindex', '0');
      i.setAttribute('title', 'Click to copy');
      i.classList.add('clickable');
      i.addEventListener('click', function() {
        copyTextToClipboard(i.textContent.trim(), function() {
          i.focus();
        });
      });
    });

  // copy file contents to clipboard
  document
    .querySelectorAll('.file-heading')
    .forEach(function(heading) {
      var next = heading.nextElementSibling;
      if(next.nodeName.toLowerCase() === 'pre' && next.classList.contains('file')) {
        next.setAttribute('tabindex', 0);
        heading.setAttribute('title', 'Click to copy');
        heading.classList.add('clickable');
        heading.addEventListener('click', function() {
          copyTextToClipboard(next.textContent.trim(), function() {
            next.focus();
          });
        });
      }
    });

  // Add active link to current page in nav
  var labID = document.body.getAttribute('data-lab-id');
  document.querySelector('#lab_' + labID + '_link a').classList.add('active');
});
