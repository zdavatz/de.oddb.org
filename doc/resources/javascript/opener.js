function open_explanation(widget_id, hidden_id, opener) {
  var callback = function() {
    var widget = dojo.widget.byId(widget_id); 
    var node = widget.domNode; 
    var pos = dojo.html.getAbsolutePosition(node);
    var viewport = dojo.html.getViewport();
    var box = dojo.html.getMarginBox(node);
    var x = pos.x;
    var y = pos.y;

    var diff = x + box.width - viewport.width;
    if(diff > 0)
      x -= diff;

    diff = y + box.height - viewport.height;
    if(diff > 0)
      y -= diff;

    dojo.lfx.html.slideTo(node, {left:x, top:y}, 500).play();
  }
  var show = dojo.lfx.toggle.fade.show(hidden_id, 500, 
                                       dojo.lfx.easeDefault, callback);
  var hide = dojo.lfx.toggle.fade.hide(opener, 500);
  dojo.lfx.chain(show, hide).play();
}
