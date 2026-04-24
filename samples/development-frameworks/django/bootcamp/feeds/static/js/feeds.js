$(function () {
  var page_title = $(document).attr("title");

  function hide_stream_update() {
    $(".stream-update").hide();
    $(".stream-update .new-posts").text("");
    $(document).attr("title", page_title);
  };

  $("body").keydown(function (evt) {
    var keyCode = evt.which?evt.which:evt.keyCode;
    if (evt.ctrlKey && keyCode == 80) {
      $(".btn-compose").click();
      return false;
    }
  });

  $("#compose-form textarea[name='post']").keydown(function (evt) {
    var keyCode = evt.which?evt.which:evt.keyCode;
    if (evt.ctrlKey && (keyCode == 10 || keyCode == 13)) {
      $(".btn-post").click();
    }
  });

  $(".btn-compose").click(function () {
    if ($(".compose").hasClass("composing")) {
      $(".compose").removeClass("composing");
      $(".compose").slideUp();
    }
    else {
      $(".compose").addClass("composing");
      $(".compose textarea").val("");
      $(".compose").slideDown(400, function () {
        $(".compose textarea").focus();
      });
    }
  });

  $(".btn-cancel-compose").click(function () {
    $(".compose").slideUp();
  });

  $(".btn-post").click(function () {
    var last_feed = $(".stream li:first-child").attr("feed-id");
    if (last_feed == undefined) {
      last_feed = "0";
    }
    $("#compose-form input[name='last_feed']").val(last_feed);
    $.ajax({
      url: '/feeds/post/',
      data: $("#compose-form").serialize(),
      type: 'post',
      cache: false,
      success: function (data) {
        $("ul.stream").prepend(data);
        $(".compose").slideUp();
        $(".compose").removeClass("composing");
        hide_stream_update();
      }
    });
  });

  $("ul.stream").on("click", ".like", function () {
    var li = $(this).closest("li");
    var feed = $(li).attr("feed-id");
    var csrf = $(li).attr("csrf");
    $.ajax({
      url: '/feeds/like/',
      data: {
        'feed': feed,
        'csrfmiddlewaretoken': csrf
      },
      type: 'post',
      cache: false,
      success: function (data) {
        if ($(".like", li).hasClass("unlike")) {
          $(".like", li).removeClass("unlike");
          $(".like .text", li).text("Like");
        }
        else {
          $(".like", li).addClass("unlike");
          $(".like .text", li).text("Unlike");
        }
        $(".like .like-count", li).text(data);
      }
    });
    return false;
  });

  $("ul.stream").on("click", ".comment", function () {
    var post = $(this).closest(".post");
    if ($(".comments", post).hasClass("tracking")) {
      $(".comments", post).slideUp();
      $(".comments", post).removeClass("tracking");
    }
    else {
      $(".comments", post).show();
      $(".comments", post).addClass("tracking");
      $(".comments input[name='post']", post).focus();
      var feed = $(post).closest("li").attr("feed-id");
      $.ajax({
        url: '/feeds/comment/',
        data: { 'feed': feed },
        cache: false,
        beforeSend: function () {
          $("ol", post).html("<li class='loadcomment'><img src='/static/img/loading.gif'></li>");
        },
        success: function (data) {
          $("ol", post).html(data);
          $(".comment-count", post).text($("ol li", post).not(".empty").length);
        }
      });
    }
    return false;
  });

  $("ul.stream").on("keydown", ".comments input[name='post']", function (evt) {
    var keyCode = evt.which?evt.which:evt.keyCode;
    if (keyCode == 13) {
      var form = $(this).closest("form");
      var container = $(this).closest(".comments");
      var input = $(this);
      $.ajax({
        url: '/feeds/comment/',
        data: $(form).serialize(),
        type: 'post',
        cache: false,
        beforeSend: function () {
          $(input).val("");
        },
        success: function (data) {
          $("ol", container).html(data);
          var post_container = $(container).closest(".post");
          $(".comment-count", post_container).text($("ol li", container).length);
        }
      });
      return false;
    }
  });

  var load_feeds = function () {
    if (!$("#load_feed").hasClass("no-more-feeds")) {
      var page = $("#load_feed input[name='page']").val();
      var next_page = parseInt($("#load_feed input[name='page']").val()) + 1;
      $("#load_feed input[name='page']").val(next_page);
      $.ajax({
        url: '/feeds/load/',
        data: $("#load_feed").serialize(),
        cache: false,
        beforeSend: function () {
          $(".load").show();
        },
        success: function (data) {
          if (data.length > 0) {
            $("ul.stream").append(data)
          }
          else {
            $("#load_feed").addClass("no-more-feeds");
          }
        },
        complete: function () {
          $(".load").hide();
        }
      });
    }
  };

  $("#load_feed").bind("enterviewport", load_feeds).bullseye();

  function check_new_feeds () {
    var last_feed = $(".stream li:first-child").attr("feed-id");
    var feed_source = $("#feed_source").val();
    if (last_feed != undefined) {
      $.ajax({
        url: '/feeds/check/',
        data: {
          'last_feed': last_feed,
          'feed_source': feed_source
        },
        cache: false,
        success: function (data) {
          if (parseInt(data) > 0) {
            $(".stream-update .new-posts").text(data);
            $(".stream-update").show();
            $(document).attr("title", "(" + data + ") " + page_title);
          }
        },
        complete: function() {
          window.setTimeout(check_new_feeds, 30000);
        }
      });
    }
    else {
      window.setTimeout(check_new_feeds, 30000);
    }
  };
  check_new_feeds();

  $(".stream-update a").click(function () {
    var last_feed = $(".stream li:first-child").attr("feed-id");
    var feed_source = $("#feed_source").val();
    $.ajax({
      url: '/feeds/load_new/',
      data: {
        'last_feed': last_feed,
        'feed_source': feed_source
      },
      cache: false,
      success: function (data) {
        $("ul.stream").prepend(data);
      },
      complete: function () {
        hide_stream_update();
      }
    });
    return false;
  });

  $("input,textarea").attr("autocomplete", "off");

  function update_feeds () {
    var first_feed = $(".stream li:first-child").attr("feed-id");
    var last_feed = $(".stream li:last-child").attr("feed-id");
    var feed_source = $("#feed_source").val();

    if (first_feed != undefined && last_feed != undefined) {
      $.ajax({
        url: '/feeds/update/',
        data: {
          'first_feed': first_feed,
          'last_feed': last_feed,
          'feed_source': feed_source
        },
        cache: false,
        success: function (data) {
          $.each(data, function(id, feed) {
              var li = $("li[feed-id='" + id + "']");
              $(".like-count", li).text(feed.likes);
              $(".comment-count", li).text(feed.comments);
          });
        },
        complete: function () {
          window.setTimeout(update_feeds, 30000);
        }
      });
    }
    else {
      window.setTimeout(update_feeds, 30000);
    }
  };
  update_feeds();

  function track_comments () {
    $(".tracking").each(function () {
      var container = $(this);
      var feed = $(this).closest("li").attr("feed-id");
      $.ajax({
        url: '/feeds/track_comments/',
        data: {'feed': feed},
        cache: false,
        success: function (data) {
          $("ol", container).html(data);
          var post_container = $(container).closest(".post");
          $(".comment-count", post_container).text($("ol li", container).length);
        }
      });
    });
    window.setTimeout(track_comments, 30000);
  };
  track_comments();

  $("ul.stream").on("click", ".remove-feed", function () {
    var li = $(this).closest("li");
    var feed = $(li).attr("feed-id");
    var csrf = $(li).attr("csrf");
    $.ajax({
      url: '/feeds/remove/',
      data: {
        'feed': feed,
        'csrfmiddlewaretoken': csrf
      },
      type: 'post',
      cache: false,
      success: function (data) {
        $(li).fadeOut(400, function () {
          $(li).remove();
        });
      }
    });
  });

  $("#compose-form textarea[name='post']").keyup(function () {
    $(this).count(255);
  });

});