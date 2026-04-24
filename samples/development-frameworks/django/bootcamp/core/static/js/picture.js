$(function () {

  var jcrop_api,
      boundx,
      boundy,
      xsize = 200,
      ysize = 200;

  $("#crop-picture").Jcrop({
    aspectRatio: xsize / ysize,
    onSelect: updateCoords,
    setSelect: [0, 0, 200, 200]
  },function(){
    var bounds = this.getBounds();
    boundx = bounds[0];
    boundy = bounds[1];
    jcrop_api = this;
  });

  function updateCoords(c) {
    $("#x").val(c.x);
    $("#y").val(c.y);
    $("#w").val(c.w);
    $("#h").val(c.h);
  };

  $("#btn-upload-picture").click(function () {
    $("#picture-upload-form input[name='picture']").click();
  });

  $("#picture-upload-form input[name='picture']").change(function () {
    $("#picture-upload-form").submit();
  });

});
