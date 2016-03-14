if($(document).find('#submenu').length)
{
	var stickytop = $('#submenu').offset().top - 50;

	var stick = function()
	{
		var scrolltop = $(window).scrollTop();

		if(scrolltop > stickytop)
		{
			$('#submenu').addClass('sticky');
			$('#submenu-container').css('height', $('#submenu').outerHeight());
		}
		else
		{
			$('#submenu').removeClass('sticky');
			$('#submenu-container').css('height', $('#submenu').outerHeight());
		}
	}

	stick();

	$(window).scroll(function()
	{
		stick();
	});
}

$(document).ready(function()
{
	$("#countryInput").change(function()
	{
		var value = $("#teamdropdown .menu").find(".selected").attr("data-id");
		$("#teamdropdown").attr("cur-id", value);
		//console.log($("#teamdropdown").attr("cur-id"));
	});

	$("#submenu .kyck-tabs li p a").each(function()
	{
		var attr = $(this).attr("data-dropdown");

		if(typeof attr !== typeof undefined && attr !== false)
		{
			$(this).click(function(event)
			{
				event.preventDefault();
			});
		}
	});

	// Shows user dropdown menu

	$("#topmenu .menu .user a:first-child").click(function()
	{
		var parent_active = false;

		if($(this).parent().hasClass("active"))
		{
			parent_active = true;
		}

		if(parent_active)
		{
			$("#topmenu .menu .user").removeClass("active");

			$(this).find(".fa").removeClass("fa-caret-up");
			$(this).find(".fa").addClass("fa-caret-down");

			$("#topmenu .menu .user .options").hide();
		}
		else
		{
			$(this).parent().addClass("active");

			$(this).find(".fa").removeClass("fa-caret-down");
			$(this).find(".fa").addClass("fa-caret-up");

			$(this).parent().find(".options").css({"visibility": "visible"});
			$(this).parent().find(".options").show();
		}

		console.log(parent_active);
	});

	// When you open the slide out menu, hide all open tabs

	$(".toggle-menu").click(function()
	{
		if($("#topmenu .menu .user").hasClass("active"))
		{
			$("#topmenu .menu .user").removeClass("active");

			$("#topmenu .menu .user").find("a:first-child .fa").removeClass("fa-caret-up");
			$("#topmenu .menu .user").find("a:first-child .fa").addClass("fa-caret-down");

			$("#topmenu .menu .user .options").hide();
		}

		$('#submenu').find('.dropdown.active.visible').each(function()
		{
			$(this).dropdown("hide");
		});
	});

});

$(document).click(function(event)
{
	$(".sublinks").each(function()
	{
		var id = $(this).attr('id');

		if($(this).hasClass("open"))
		{
			$("#submenu .kyck-tabs li p a").each(function()
			{
				if($(this).attr('data-dropdown') == id)
				{
					$(this).addClass("open");
					return;
				}
			});
		}
		else
		{
			$("#submenu .kyck-tabs li p a").each(function()
			{
				if($(this).attr('data-dropdown') == id)
				{
					$(this).removeClass("open");
					return;
				}
			});
		}
	});

	// Hides user dropdown menu

	if($(event.target).closest('#submenu .dropdown').length === 0)
	{
		$('#submenu').find('.dropdown.active.visible').each(function()
		{
			$(this).dropdown("hide");
		});
	}

	if ($(event.target).closest('#topmenu .menu .user').length === 0)
	{

		$("#topmenu .menu .user").removeClass("active");

		$("#topmenu .menu .user").find("a:first-child .fa").removeClass("fa-caret-up");
		$("#topmenu .menu .user").find("a:first-child .fa").addClass("fa-caret-down");

		$("#topmenu .menu .user .options").hide();
	}
});
