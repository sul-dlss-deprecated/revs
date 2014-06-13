$(document).ready(function(){

  function split( val ) {
      return val.split( /\|\s*/ ); // multivalued delimiter goes here
    }
    function extractLast( term ) {
      return split( term ).pop();
    }
 
    $( ".autocomplete" ).bind( "keydown", function( event ) {
        field=$(this).data('autocomplete-field');
        if ( event.keyCode === $.ui.keyCode.TAB &&
            $( this ).data( "ui-autocomplete" ).menu.active ) {
          event.preventDefault();
        }
      });

      $( ".autocomplete.mvf").autocomplete({
        source: function( request, response ) {
          $.getJSON( "/autocomplete.json", {
            field: field,
            term: extractLast( request.term )
          }, response );
        },
        search: function() {
          var term = extractLast( this.value );
          if ( term.length < 2 || term.length > 10) {
            return false;
          }
        },
        focus: function() {return false;},
        select: function( event, ui ) {
          var terms = split( this.value );
          terms.pop();
          terms.push( ui.item.value );
          terms.push( "" );
          this.value = terms.join( " | " ); // multivalued delimiter also goes here
          return false;
        }
      });

   $( ".autocomplete.single").autocomplete({
        source: function( request, response ) {
          $.getJSON( "/autocomplete.json", {
            field: field,
            term: extractLast( request.term )
          }, response );
        },
        minLength: 2,
        max: 10});      
});