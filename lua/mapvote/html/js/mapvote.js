
var IN_ENGINE = navigator.userAgent.indexOf( "Valve Source Client" ) != -1;

var MapVote = {
    GuiWidth: 600,
    GuiHeight: 600,
    Gamemodes: [],
    Feedback: 0,
    SetSize: function( width, height ) {
        $( "#maps" ).css( "width", width + "px" ).css( "height", height + "px" ).css( "left", -(width / 2) + "px" );
        MapVote.RecalculatePositions();
    },
    AddGamemode: function( name, shorthand, color ) {
        MapVote.Gamemodes[name] = {
            name: name,
            shorthand: shorthand,
            color: color
        };
        $( "[mv-gamemode='" + name.replace(/'/g, "\\'") + "']" ).each( function() {
            MapVote.AddGamemodeInfo( $( this ) );
        } );
    },
    AddMap: function( name, gamemode, previewURL, score ) {
        var node = $( "[mv-map='" + name.replace(/'/g, "\\'") + "']" );
        if (node.length > 0) {
            return;
        }
        var image = $( document.createElement( "IMG" ) );
        image.attr( "src", previewURL ).attr( "alt", name );
        image.bind( "error", function() {
            MapVote.OnMissingImage( $( this ) );
        } );
        
        node = $( document.createElement( "DIV" ) );
        node.attr( "mv-map", name ).attr( "mv-gamemode", gamemode);
        node.addClass( "map" );
        node.append( $( document.createElement( "DIV" ) ).addClass( "imagecontainer" ).append( image ) );
        node.append( $( document.createElement( "DIV" ) ).addClass( "mapname" ).addClass( "outlined" ).html( name ) );
        node.append( $( document.createElement( "DIV" ) ).addClass( "avatars" ) );
        node.click( function( e ) {
            MapVote.VoteFor( $( this ).attr( "mv-map" ) );
        } );

        var stars = $( document.createElement( "SPAN" ) );
        stars.addClass( "map-stars" );
        for (var i = 0; i < 5; i++) {
            var star = $( document.createElement( "DIV" ) );
            star.addClass( "star" );
            if (i + 1 > score) {
                star.addClass( "star-grey" );
            }
            stars.append( star );
        }
        node.append( stars );
        
        MapVote.AddGamemodeInfo( node );
        
        $( "#maps" ).append( node );
    },
    AddVoter: function( name, mapName ) {
        var node = $( "[mv-nickname='" + name.replace(/'/g, "\\'") + "']" );
        if (node.length > 0) {
            node.attr( "mv-vote", mapName );
            MapVote.RecalculatePositions();
            return;
        }
        
        node = $( document.createElement( "DIV" ) );
        node.attr( "mv-nickname", name ).attr( "mv-vote", mapName );
        node.attr( "title", name ).addClass( "voter" ).append( $( "#templates > #loading" ).clone() );
        
        $( "#voters" ).append( node );
        setTimeout( function() { MapVote.RecalculatePositions(); }, 1 );
    },
    AddVoterAvatar: function( name, avatarURL ) {
        var svg = $( "[mv-nickname='" + name.replace(/'/g, "\\'") + "'] #loading" );
        var image = $( document.createElement( "IMG" ) );
        image.attr( "src", avatarURL ).attr( "alt", name );
        image.bind( "error", function() {
            MapVote.OnMissingImage( $( this ) );
        } );
        svg.replaceWith( image );
    },
    RecalculatePositions: function() {
        $( "[mv-map]" ).each( function() {
            var mapNode = $( this );
            var avatarsNode = mapNode.find( ".avatars" );
            var width = avatarsNode.width() - 6;
            var height = avatarsNode.height() + 3;
            var nodes = $( "[mv-vote='" + mapNode.attr( "mv-map" ).replace(/'/g, "\\'") + "']" );
            var avatarSize = 32;
            var rows = 1;
            var columns = 0;
            var totalWidth = width;
            var fit = false;
            // IT WORKS, DON'T ASK ME HOW
            for (; !fit; avatarSize--) {
                var counter = nodes.length;
                rows = 1;
                for (var row = 0; counter > 0 && (avatarSize + 7) * (row + 1) < height; row++) {
                    if (row == 0) {
                        columns = 1;
                    }
                    for (var column = 1; counter > 0 && (avatarSize + 7) * column < width; column++) {
                        if (row == 0) {
                            columns++;
                        }
                        counter--;
                    }
                    if (counter > 0) {
                        rows++;
                    }
                }
                if (counter <= 0) {
                    fit = true;
                }
            }
            var avatarsPosition = avatarsNode.position();
            var mapPosition = mapNode.position();
            var contentPosition = $( "#contentholder" ).position();
            var left = contentPosition.left + mapPosition.left + avatarsPosition.left + 5;
            var top = contentPosition.top + mapPosition.top + avatarsPosition.top;
            nodes.each( function( index ) {
                var currTop = 0;
                while (columns != 0 && index >= columns) {
                    currTop += avatarSize + 7;
                    index -= columns;
                }
                var currLeft = (avatarSize + 7) * index;
                $( this ).height( avatarSize ).width( avatarSize ).css( "left", left + currLeft ).css( "top" , top + currTop );
            } );
        } );
    },
    AddGamemodeInfo: function( node ) {
        var gamemode = MapVote.Gamemodes[node.attr( "mv-gamemode" )];
        if (gamemode != null) {
            if ( node.find( ".gamemode" ).length == 0 ) {
                node.find( ".imagecontainer" ).append( $( document.createElement( "DIV" ) ).addClass( "gamemodecontainer" ).append( $( document.createElement( "DIV" ) ).addClass( "gamemode" ) ) );
            }
            node.find( ".gamemode" ).html( gamemode.shorthand ).css( "background-color", gamemode.color );
        }
    },
    VoteFor: function( map ) {
        if (IN_ENGINE) {
            MapVoteLua.Vote( map );
        } else {
            MapVote.votes = MapVote.votes + 1;
            MapVote.AddVoter( "Voter" + MapVote.votes, map );
            if (MapVote.votes > 5) {
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 0 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 200 );
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 400 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 600 );
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 800 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 1000 );
            }
        }
    },
    OnMissingImage: function( node ) {
        node.replaceWith( $( "#templates > #missing" ).clone() );
    },
    UpdateTimer: function( content ) {
        $( "#timer" ).text( content );
    },
    BlinkMap: function( name, on ) {
        if (on) {
            $( "[mv-map='" + name.replace(/'/g, "\\'") + "']" ).removeClass( "blinkoff" ).addClass( "blinkon" );
        } else {
            $( "[mv-map='" + name.replace(/'/g, "\\'") + "']" ).removeClass( "blinkon" ).addClass( "blinkoff" );
        }
    },
    GetAvatarFromXML: function( url ) {
        var doc = null;
        if (window.DOMParser) {
            var parser = new DOMParser();
            doc = parser.parseFromString( data, "text/xml" );
        }
        else {
            doc = new ActiveXObject( "Microsoft.XMLDOM" );
            doc.async = false;
            doc.loadXML( data ); 
        }
        return $( doc ).find( "profile > avatarIcon" ).text();
    },
    GiveFeedback: function( score ) {
        if (IN_ENGINE) {
            MapVoteLua.Feedback( score );
        }
        MapVote.Feedback = score;
    }
};

function clamp( number, min, max ) {
    return Math.max(min, Math.min(number, max));
}

$( window ).load( function() {
    var stars = $( "#feedback-stars" );
    for (var i = 0; i < 5; i++) {
        var star = $( document.createElement( "DIV" ) );
        star.addClass( "star" ).addClass( "star-grey" ).attr( "mapvote-score", i + 1 );
        stars.append( star );
    }
    stars.find( ".star" ).mouseenter( function() {
        var star = $( this );
        $( "#feedback-stars .star" ).each( function( index ) {
            var current = $( this );
            if (current.attr( "mapvote-score" ) <= star.attr( "mapvote-score" )) {
                current.removeClass( "star-grey" );
            }
            else {
                current.addClass( "star-grey" );
            }
        } );
    } ).mouseleave( function() {
        $( "#feedback-stars .star" ).each( function( index ) {
            var current = $( this );
            if (MapVote.Feedback > 0 && MapVote.Feedback >= current.attr( "mapvote-score" )) {
                current.removeClass( "star-grey" );
            } else {
                current.addClass( "star-grey" );
            }
        } );
        for (var j = 0; j < 5; j++) {
        }
    } ).click( function() {
        var star = $( this );
        MapVote.GiveFeedback( star.attr( "mapvote-score" ) );
    } );
} );

if (!IN_ENGINE) {
    $( window ).load( function() {
        //$( document.body ).addClass( "debug" );
        $( document.body ).wrapInner( $( document.createElement( "div" ) ).attr( "id", "debug" ) ).css( "background-image", "url('background.png')" );
    } );
    
    MapVote.votes = 0;
}
