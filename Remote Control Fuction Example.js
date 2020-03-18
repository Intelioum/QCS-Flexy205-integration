
var deviceName = 'DEVICE NAME'
var tagName = 'TAG NAME'
var tagValue = 'TAG VALUE'
var t2maccount = 'T2M ACCOUNT ID'
var t2musername = 'T2M USERNAME'
var t2mpassword = 'T2M PASSWORD'
var t2mdeveloperid = 'T2M DEVELOPER ID'
var t2mdeviceusername = 'FLEXY USERNAME'
var t2mdevicepassword = 'FLEXY PASSWORD'
var HttpClient = function () {
	this.get = function (aUrl, aCallback) {
		var anHttpRequest = new XMLHttpRequest();
		anHttpRequest.onreadystatechange = function () {
			if (anHttpRequest.readyState == 4 &&
				anHttpRequest.status == 200)
				aCallback(anHttpRequest.responseText);
		}

		anHttpRequest.open("GET", aUrl, true);
		anHttpRequest.send(null);
	}
}
var client = new HttpClient();
client.get('https://m2web.talk2m.com/t2mapi/get/' +
	deviceName + '/rcgi.bin/UpdateTagForm?TagName1=' +
	tagName + '&TagValue1=' + tagValue + '&t2maccount=' +
	t2maccount + '&t2musername=' + t2musername +
	'&t2mpassword=' + t2mpassword + '&t2mdeveloperid=' +
	t2mdeveloperid + '&t2mdeviceusername=' +
	t2mdeviceusername + '&t2mdevicepassword=' +
	t2mdevicepassword,
	function (response) {
		// do something with response
	});

