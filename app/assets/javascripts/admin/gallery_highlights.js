$(document).ready(function(){
  // Called when a curator user checks the galleries featured checkbox
  $('.gallery-highlight-checkbox').change(function() {
    var gallery_id = $(this).data('id');
    var checked = $(this).prop('checked');
		$.ajax({
		        type: "POST",
		        url: "/admin/gallery_highlights/set_highlight/" + gallery_id,
						data: "highlighted=" + checked
		});
  });
  
    $("#galleries_list").sortable({
    axis: 'y',
    dropOnEmpty: false,
    handle: '.handle',
    cursor: 'move',
    items: 'tr.galleries-row',
    opacity: 0.4,
    scroll: true,
    update: function(e,ui){
      item_id=ui.item.data('gallery-id');
      position=ui.item.index();
      $.ajax({
        type: 'post',
        data: {id: item_id, position: position},
        dataType: 'script',
        url: '/admin/gallery_highlights/sort'})
      }
    });

    $('.handle').removeClass('hidden hidden-offscreen');
    $('.handle').show();

});