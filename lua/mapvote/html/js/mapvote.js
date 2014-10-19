
var IN_ENGINE = navigator.userAgent.indexOf( "Valve Source Client" ) != -1;

var MapVote = {
    GuiWidth: 600,
    GuiHeight: 600,
    Gamemodes: [],
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
    AddMap: function( name, gamemode, previewURL ) {
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
        node.append( $( document.createElement( "DIV" ) ).addClass( "mapname" ).html( name ) );
        node.append( $( document.createElement( "DIV" ) ).addClass( "avatars" ) );
        node.click( function( e ) {
            MapVote.VoteFor( $( this ).attr( "mv-map" ) );
        } );
        
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
        node.attr( "title", name ).addClass( "voter" ).append( $( "#svgcontainer > #loading" ).clone() );
        
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
            var width = avatarsNode.width();
            var nodes = $( "[mv-vote='" + mapNode.attr( "mv-map" ).replace(/'/g, "\\'") + "']" );
            var size = clamp( 32, 0, width / clamp( nodes.length, 5, mapNode.height() ) - 7 );
            var avatarsPosition = avatarsNode.position();
            var mapPosition = mapNode.position();
            var mapsPosition = $( "#maps" ).position();
            var left = mapsPosition.left + mapPosition.left + avatarsPosition.left + 3;
            var top = mapsPosition.top + mapPosition.top + avatarsPosition.top + 2;
            nodes.each( function( index ) {
                $( this ).height( size ).width( size ).css( "left", left + (size + 7) * index ).css( "top" , top );
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
        if (!IN_ENGINE) {
            MapVote.votes = MapVote.votes + 1;
            MapVote.AddVoter( "Voter" + MapVote.votes, map );
            if ( MapVote.votes > 5 ) {
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 0 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 200 );
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 400 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 600 );
                setTimeout( function() { MapVote.BlinkMap( map, true ); }, 800 );
                setTimeout( function() { MapVote.BlinkMap( map, false ); }, 1000 );
            }
        } else {
            MapVoteLua.Vote( map );
        }
    },
    OnMissingImage: function( node ) {
        node.replaceWith( $( "#svgcontainer > #missing" ).clone() );
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
    }
};

function clamp( number, min, max ) {
    return Math.max(min, Math.min(number, max));
}

if (!IN_ENGINE) {
    window.onload = function() {
        $( document.body ).addClass( "debug" );
        $( document.body ).wrapInner( $( document.createElement( "div" ) ).attr( "id", "debug" ) ).css( "background-image", "url('background.png')" );
    }
    
    MapVote.votes = 0;
}
