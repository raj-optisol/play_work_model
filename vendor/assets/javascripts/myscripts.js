alert("JavaScript Running.");

var menuHeight = 50;
var stickyNavTop = $('#sub-menu').offset().top - menuHeight;

var stickyNav = function(){
var scrollTop = $(window).scrollTop();
     
if (scrollTop > stickyNavTop) { 
    $('#sub-menu').addClass('sticky');
    $('.sub-menu-container').css('height', $('#sub-menu').outerHeight());
} else {
    $('#sub-menu').removeClass('sticky'); 
    $('.sub-menu-container').css('height', $('#sub-menu').outerHeight());
}
};

stickyNav();

$(window).scroll(function() {
    stickyNav();
});

$('.top').click(function()
{
    $("html, body").animate({ scrollTop: 0 }, 500, "easeOutExpo");
    return false;
});

var expanded = false;

$('#menu-button').click(function()
{
    if(expanded)
    {
        $('#wrapper').css({'position': 'relative'});
        $('#wrapper').animate({'left': '0'}, 600, 'easeOutExpo');
        expanded = false;
    }
    else
    {
        $('#wrapper').css({'position': 'relative'});
        $('#wrapper').animate({'left': '-300px'}, 600, 'easeOutExpo');
        expanded = true;
    }
});


function DropDown(el) {
    this.dd = el;
    this.placeholder = this.dd.children('span');
    this.opts = this.dd.find('ul.dropdown > li');
    this.val = '';
    this.index = -1;
    this.initEvents();
}
DropDown.prototype = {
    initEvents : function() {
        var obj = this;
 
        obj.dd.on('click', function(event){
            $(this).toggleClass('active');
            return false;
        });
 
        obj.opts.on('click',function(){
            var opt = $(this);
            obj.val = opt.text();
            obj.index = opt.index();
            obj.placeholder.text('Gender: ' + obj.val);
        });
    },
    getValue : function() {
        return this.val;
    },
    getIndex : function() {
        return this.index;
    }
}
