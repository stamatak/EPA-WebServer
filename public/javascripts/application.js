// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function optionalButton(id,name){
    var vis = document.getElementById(id).style.display;
    if (vis == 'block'){
        document.getElementById(id).style.display = 'none';
        document.getElementsByName(name)[0].value='show more options';  
    }
    else{
        document.getElementById(id).style.display = 'block';
        document.getElementsByName(name)[0].value='hide more options';
    }
                  
}

function optionalCheckboxElementsSpeed(speed_id,speed_name,heu_id,heu_name){
    var speed = document.getElementById(speed_name);
    var heuristic = document.getElementById(heu_name);

    // if Fast is checked then uncheck Heuristics
    if (speed.checked){
        document.getElementById(heu_name).checked = false;
        document.getElementById(heu_id).style.display = 'none';
    }
}

function optionalCheckboxElementsHeuristics(speed_id,speed_name,heu_id,heu_name){
    var speed = document.getElementById(speed_name);
    var heuristic = document.getElementById(heu_name);
     // if Heuristics is checked, then uncheck Bootstrapping and Fast
    if (heuristic.checked){
        document.getElementById(heu_id).style.display = 'block';
        document.getElementById(heu_name).checked = true;
        document.getElementById(speed_name).checked = false;
    }
    // if Heuristics is unchecked, hide
    else{
        document.getElementById(heu_id).style.display = 'none';
        document.getElementById(heu_name).checked = false;
    }
}

function optionalCheckboxElementsBootstrap(speed_id,speed_name,boot_id,boot_name,heu_id,heu_name){
    var speed = document.getElementById(speed_name);
    var bootstrap = document.getElementById(boot_name);
    var heuristic = document.getElementById(heu_name);
    // if Bootstrapping is checked, then uncheck Heuristics
    if(bootstrap.checked){
        document.getElementById(boot_id).style.display = 'block';
        document.getElementById(heu_id).style.display = 'none';
        document.getElementById(heu_name).checked = false;
    } 
    // if Bootstrapping is unchecked, hide
    else{
        document.getElementById(boot_id).style.display = 'none';
        document.getElementById(boot_name).checked = false;
    }
}

function showHideCheckboxElements(checkboxID, elementsID){
    var vis = document.getElementById(checkboxID);
    if (vis.checked){
        document.getElementById(elementsID).style.display = 'block';
    }
    else {
        document.getElementById(elementsID).style.display = 'none';
    }
}

function showTooltip(id, event)
{
    var yoffset = parseInt(document.body.scrollTop);
    var xoffset = parseInt(document.body.scrollLeft);
    var mouseY = (event.clientY) ? event.clientY : event.pageY;
    var mouseX = (event.clientX) ? event.clientX : event.pageX;
    document.getElementById(id).style.top  = mouseY + 20 + yoffset+ "px";
    document.getElementById(id).style.left = mouseX + 10 + xoffset + "px";
    document.getElementById(id).style.visibility = "visible";
   }
function hideTooltip(id)
   {
      document.getElementById(id).style.visibility = "hidden";
   }

function isEven(n){
    if (n % 2 > 0){
        document.getElementById(n).style.backgroundColor= "#ffffff";
    }
    else{
        document.getElementById(n).style.backgroundColor= "#e2ecf3";
    }
}

function noPlacementsHint(file){
    if (file == "treefile_no_placements.phyloxml"){
        alert("The results are too large, for this reason the treeviewer will only show a tree without any placements!\nYou can download the treeviewer on this page and try to run it on your local machine.");
    }
        

}