function switch_formatter() {
    var selected_format = $('input[@name=formatter]:checked').val();
    if (selected_format == 'ubb') {
        $('.ubb').show();
        $('.wiki').hide();
    } else if (selected_format == 'wiki') {
        $('.ubb').hide();
        $('.wiki').show();
    } else {
        $('.ubb').hide();
        $('.wiki').hide();
    }
}
$(document).ready(function() {
    switch_formatter();
} );