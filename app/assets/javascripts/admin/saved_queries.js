$(document).ready(function(){
  
    $("#admin-saved_queries").sortable({
    axis: 'y',
    dropOnEmpty: false,
    handle: '.handle',
    cursor: 'move',
    items: 'tr.saved_queries-row',
    opacity: 0.4,
    scroll: true,
    update: function(e,ui){
      item_id=ui.item.data('saved_query-id');
      position=ui.item.index() - 1;
      $.ajax({
        type: 'post',
        data: {id: item_id, position: position},
        dataType: 'script',
        url: '/admin/saved_queries/sort'})
      }
    });

    $('.handle').removeClass('hidden hidden-offscreen');
    $('.handle').show();

});