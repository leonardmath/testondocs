$(document).on('daPageLoad', function () {
    $('form').on('change', 'input, select, textarea', function () {
      $(this).closest('.da-form-group').addClass('da-modified');
  
      if (!$('#autosave-toast').length) {
        $('body').append(
          '<div id="autosave-toast" style="position:fixed;bottom:20px;right:20px;background:#28a745;color:white;padding:10px 20px;border-radius:5px;display:none;z-index:9999;">💾 Salvo</div>'
        );
      }
  
      $('#autosave-toast').fadeIn().delay(1500).fadeOut();
    });
  });
  