$(function(){
	if(default_data){
		var logged_in = default_data.logged_in;
		var user = default_data.user;
		var lastUpdate = new Date(default_data.loaded);
		var controls = default_data.controls;
	}else{
		var logged_in = false;
		var user = null;
		var lastUpdate = new Date();
		var controls = false;
	}

	var favButton = function(e){
		var matched = $(this).attr('id').match(/addFav_(\d+)/);
		if(!matched){return null;}
		var mesId = matched[1];
		$.ajax({
			type:"POST",
			url: apiBase + "/messages/"+mesId+"/add_fav.json",
			data:{ since:Math.floor(lastUpdate.getTime()/1000) },
			dataType:"json",
			success:post_favButton,
		});
	}

	function autoLink(j){
		var regURL = /(http:\/\/[^'"\s　]+)/;
		var s = j.text().split(regURL);
		var r = '';
		for(var i=0;i<s.length;i++){
			if(s[i].match(regURL)){
				var a = $('<span>').append($('<a>').attr({target:"_blank",href:s[i]}).text(s[i]));
				r += a[0].innerHTML;
			}else{
				var a =  $('<span>').text(s[i]);
				r += a[0].innerHTML;
			}
		}
		return j.html(r);
	}

	function post_favButton(data){
		if(!data.logged_in){pre_login()}
		if(data.recent){newInformations(data.recent)}
	}
	function loginCheck(data){
		if(data.logged_in == false){
			pre_login();
		}
	}

	function newInformations(data){
		if(!data){return null}
		var m,u,f;
		if(data.time){
			lastUpdate = new Date(data.time*1000);
		}
		if(m = data.messages){
			for(var i=0;i<m.length;i++){
				addMessage(m[i]);
			}
		}

		if(u = data.users){
			var ids=[];
			for(var i=0;i<u.length;i++){
				var liid = 'user_'+u[i].id;
				ids.push(liid)
				if($('#'+liid).length==0){
					$('#members ul').append($('<li class="member">').attr({id:liid}).text(u[i].name));
				}
			}
			for(var i=$('#members ul li.member').length-1;i>=0;i--){
				if(ids.indexOf($($('#members ul li.member')[i]).attr('id')) < 0){
					$('#members ul')[0].removeChild($('#members ul li.member')[i])
				}
			}
		}

		if(f = data.favs){
			for(var i=0;i<f.length;i++){
				var n = $('#favNum_'+f[i].message_id);
				if(n.length>0){
					if(parseInt(n.text())!=f[i].total){
						n.text(f[i].total)
						$('#favStars_'+f[i].message_id).text(manyStars(f[i].total))
					}
				}
			}
		}
	}

	function login(e){
		$.ajax({
			type:"POST",
			url: apiBase + "/user/login.json",
			data:{
				name:$('#screenNameInput').val(),
				since:Math.floor(lastUpdate.getTime()/1000),
			},
			dataType:"json",
			success: post_login,
			error: fail_login,
		});
		$('.screenMessage').text('Loading...');
	}

	function manyStars(t){
		s = '';
		for(var i=0;i<t;i++){ s += '★'; }
		return s;
	}
	function addMessage(m){
		var mId = "message_"+m.id;
		if($('#'+mId).length){return null}
		var messageDiv = $('<div id="'+mId+'" class="message">').hide();
		var messageName = $('<div class="name">').text(m.name)
		var messageContent = $('<div class="content">').text(m.content)
		var messageTime = $('<div class="time">').text(m.created)
		autoLink(messageContent)
		var messageFav = $('<div class="favs">').append(
				$('<div class="favStars">').attr({id:"favStars_"+m.id}).text(manyStars(m.favs))
				).append(
				$('<div class="favNum">').attr({id:"favNum_"+m.id}).text(m.favs)
				).append(
				$('<button class="addFav" id="addFav_'+m.id+'">').text('★+').click(favButton));
		messageDiv.append(messageName).append(messageContent).append(messageTime).append(messageFav);
		$('#messages').prepend(messageDiv);
		messageDiv.slideDown();
	}

	function newMessage(){
		var mes = $('#controlMessageInput').val();
		$.ajax({
			type:"POST",
			url: apiBase + "/messages/new.json",
			data:{
				message:mes,
				since:Math.floor(lastUpdate.getTime()/1000)
			},
			dataType:"json",
			success: post_newMessage,
		});
		$('#controlMessageInput').val('');
	}
	function post_newMessage(data){
		if(!data.logged_in){pre_login()}
		if(data.recent){newInformations(data.recent)}
	}

	function fail_login(data){
		$('#screenLogin .screenMessage').empty().append($('<p>Login Failed</p>')).append($('<p>').text(data.warn));
	}

	function post_login(data,dataType){
		if(data.complete){
			user = data.name;
			$('#controlName').text(user);
			$('#screenLogin .screenMessage').text('Logged In');
			$('body').css({overflow:'visible'});
			$('#screenLogin').hide();
			$('#screen').fadeOut();
			$('.addFav').removeAttr('disabled');
		}else{
			fail_login(data);
		}
	}

	function pre_login(){
		$('#screenLgoin .screenMessage').empty();
		$('#screenLogin').show();
		$('#screen').show();
		$('body').css({overflow:'hidden'});
		$('.addFav').attr({disabled:true});
	}


	$('#loginForm').bind('submit',function(e){e.preventDefault();login();});
	if(!logged_in){ $('.addFav').attr({disabled:true}); }

	if(controls){
		if(!logged_in){ pre_login(); }
		$('#controlForm').bind('submit',function(e){e.preventDefault();newMessage();});
		setInterval(function(){
			$.ajax({
				type:"get",
				url: apiBase + "/chat/recent.json",
				dataType:"json",
				data:{
					since:Math.floor(lastUpdate.getTime()/1000)
				},
				success: newInformations,
			});
		},5000);


		$('#showMembersButton').click(function(){
			$('#members ul').slideToggle();
			$(this).text($(this).text()==='▼'?'▲':'▼');
		});
	}
	$(window).bind('resize',function(){
	  $('#screen').css({width:$(this).width(),height:$(this).height()});
	}).trigger('resize');
	$('.addFav').click(favButton);
});
