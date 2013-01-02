var twincle;

function Twincle (uri)
{
    this.setupWebSocket(uri);
    this.setupWindowTitle( );
    this.bindKeyEvent( );

    $('.dropdown-toggle').dropdown( );
    twincle = this;
}

Twincle.prototype = {
    ws: null,

    setupWebSocket: function (uri) {
        var ws  = new WebSocket(uri);
        ws.binaryType = 'arraybuffer';
        this.ws = ws;

        ws.onopen = function ( ) {
            console.log('connected');
        };

        ws.onclose = function (ev) {
            console.log(ev);
            console.log('closed');
        };

        ws.onmessage = function (ev) {
            var data = msgpack.unpack(new Uint8Array(ev.data));

            switch (data.type) {
                case 'stream':
                    $('#timeline').prepend( $(data.body).hide( ).fadeIn( ) );

                    if (!document.hasFocus( )) {
                        $('title').trigger('twincle.unread');
                    }
                    break;

                case 'join':
                    $('#members').append(data.body);
                    break;

                case 'leave':
                    var id = data.body;
                    $('#' + id).remove( );
                    break;

                default:
                    console.log(data);
            }
        };

        ws.onerror = function (ev) {
            console.log('error' + ev);
        };
    },

    setupWindowTitle: function ( ) {
        var title  = document.title;
        var unread = 0;

        $(window).focus( function ( ) {
            unread = 0;
            $('title').text(title);
        } );

        $('title').on('twincle.unread', function (ev) {
            $(this).text('(' + ++unread + ') ' + title);
        } );
    },

    bindKeyEvent: function ( ) {
        $('#tweet-editor').keypress( function (ev) {
            if (ev.keyCode == 13) {  // Enter
                $('#tweet-send').trigger('click');
                return false;
            }
        } ).keyup( function (ev) {
            if ( $(this).val( ).length == 0 ) {
                $('#tweet-send').addClass('disabled').removeClass('btn-primary');
            }
            else {
                $('#tweet-send').addClass('btn-primary').removeClass('disabled');
            }
        } );

        $('#tweet-send').click( function ( ) {
            var elem  = $('#tweet-editor');
            var tweet = $(elem).val( );

            if (tweet.length > 0) {
                twincle.sendMessage('stream', 'Lounge', tweet);
            }

            $(elem).val('');
            $(this).addClass('disabled').removeClass('btn-primary');
        } );
    },

    sendMessage: function (type, room, message) {
        var data = {
            type: type,
            room: room,
            body: message
        };

        twincle.ws.send(new Uint8Array(msgpack.pack(data)).buffer);
    }
}
