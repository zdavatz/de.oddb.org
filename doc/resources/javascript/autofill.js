function autofill(form, key, url)
{
  document.body.style.cursor = 'wait';
  form.confirm_pass.disabled = false;
  var val = form[key].value;
  dojo.io.bind({
		url: url + val,
		load: function(type, data, evt) { 
      var retkey;
      var retval;
      for(retkey in data) {
        if(retval =  data[retkey])
          form[retkey].value = retval;
      }
      if(data['email'])
        form.confirm_pass.disabled = true;
      document.body.style.cursor = 'auto';
		},
		mimetype: "text/json"
	});
}
