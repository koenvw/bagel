var Popup = {}
Popup = {
	loading: function(type) {
		Element.show('spinner_'+type);
		Form.disable('form-'+type+'-add');
	},
	complete: function(type) {
		Element.hide('add-'+type+'-popup');
		Element.hide('spinner_'+type);
		Form.enable('form-'+type+'-add');
		Element.hide(type+'_item_none');
	},
	complete_inline: function(type) {
		Element.hide('spinner_'+type);
		Form.enable('form-'+type+'-add');
	}
}
function remove_element_from_list(container_id, element_id)
{
    $(container_id).removeChild($(element_id))
}
function deleteRow(tblName, rowName)
{
  var tbl = document.getElementById(tblName);
  var row = document.getElementById(rowName);
  if (tbl != null && row != null)
  {
	tbl.deleteRow(row.rowIndex);
  }
}
function toggle_checkbox(chk)
{
  $(chk).checked = true
}
function toggle_popup(type) {
    var popup = $('add-'+type+'-popup');
    //center(popup);
    Element.toggle(popup);
}
function center(element) {
    var header = $('header')
    element = $(element);
    element.style.position = 'fixed'
    var dim = Element.getDimensions(element)
    element.style.top = '200px';
    element.style.left = ((header.offsetWidth - dim.width) / 2) + 'px';
}
