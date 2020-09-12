/*************************************************************************************************/
/***************************************** Leiamídia *********************************************/
/*************************************************************************************************/
/*                                                                                               */
/*     1   - print notices based on crawler's text file                                          */
/*         - setup the webcam                                                                    */
/*         - make server listening on server_port                                                */
/*         - prepare to send messages on client_port                                             */
/*                                                                                               */
/*     2   - wait for mouseClick in one notice                                                   */
/*         - update all notices based on update_notices_delay                                    */
/*                                                                                               */
/*     3   - reprint the screen                                                                  */
/*         - showing notice information                                                          */
/*         - start the webcam                                                                    */
/*         - start recording audio based on audio_record_start_delay                             */
/*         - send osc messages based on record_speed                                             */
/*         - print rect and circle predictions when receive OSC msg                              */
/*         - make webcam effect based on emotion prediction                                      */ 
/*                                                                                               */
/*                                                                                               */
/*         Author: João Teixeira Araújo                                                          */
/*                                                                                               */
/*************************************************************************************************/



/********************************************************************************************************************************************************************************/
/************************************************************************************ IMPORTS ***********************************************************************************/
/********************************************************************************************************************************************************************************/


import java.nio.file.Paths;
import java.io.FileReader; 
import java.util.Iterator; 
import java.nio.file.CopyOption;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.io.IOException;

import java.text.SimpleDateFormat;  
import java.util.Date;  

import ddf.minim.*;
import ddf.minim.ugens.*;
import java.util.Map; 

import java.net.URL;
  
import org.json.simple.JSONArray; 
import org.json.simple.JSONObject; 
import org.json.simple.parser.*; 

import processing.video.*;

import oscP5.*;
import netP5.*;


/********************************************************************************************************************************************************************************/
/******************************************************************************** VARIABLES TO SET ******************************************************************************/
/********************************************************************************************************************************************************************************/


// set the ip and OSC client/server ports
String ip = "127.0.0.1";
int server_port = 9001;
int client_port = 9063;

// full path for notices images
String crawler_path = "/home/joao/Desktop/git/leia_midia/notices_crawler/";

// delay of notices update
int update_notices_delay = 10000;


/********************************************************************************************************************************************************************************/
/******************************************************************************** STATIC VARIABLES ******************************************************************************/
/********************************************************************************************************************************************************************************/


// for webcam
Capture cam;

// to audio recorder
Minim minim;
AudioPlayer player;
AudioInput in;
AudioRecorder recorder;  

// for osc communication
OscP5 oscP5;
NetAddress myRemoteLocation;

// used to print all images
PImage img;

// to store the notices information
ArrayList<String> titles = new ArrayList<String>(); 
ArrayList<String> descriptions = new ArrayList<String>();
ArrayList<String> authors = new ArrayList<String>();
ArrayList<String> date_publishs = new ArrayList<String>();
ArrayList<String> image_urls = new ArrayList<String>();
ArrayList<String> maintexts = new ArrayList<String>();

// to make selection color effect in notices title 
ArrayList<Integer> rectX = new ArrayList<Integer>(); 
ArrayList<Integer>  rectY = new ArrayList<Integer>();      
int rect_size_x = 1300;     // Diameter of rect
int rect_size_y = 150;
color rectColor, baseColor;
color rectHighlight;
color currentColor;
ArrayList<Boolean> rectOver = new ArrayList<Boolean>();

// to make restart button
Integer button_restart_x; 
Integer button_restart_y;      
color button_restart_color_up, button_restart_color_down;
Boolean button_restart_mouse_over;

// to store the last prediction information
String lastEmotion = "";
String lastFearPercent = "";
String lastHappyPercent = "";
String lastSadPercent = "";

// full path for sound recorders
String sound_path = "./sounds/";

// set the speed of the legend in webcam and the audio record
int legend_speed = 10;
int record_speed = 70;

// set the delay time for audio starts the records
int audio_record_start_delay = 70;


// to get what is the currently page
// true = first page;
// false = second page;
Boolean current_page = true;

Boolean reset_webcam_effects = false;

// this variable get the notices, format it, and print below the webcam
String legend_titles = "                                                            ";

// to set the name of the new recorded audio, ex: 251.wav if haves 250 in directory
int sound_rec_count;

/********************************************************************************************************************************************************************************/
/******************************************************************************* CONTROL VARIABLES ******************************************************************************/
/********************************************************************************************************************************************************************************/


// to controll OSC messages
Boolean flagOscReceived = false;


// for time count; in processing if we use delay() function, it will freeze the software
int time_record;
int time_legend;
int time_notice_update;


/********************************************************************************************************************************************************************************/
/************************************************************************************** SETUP ***********************************************************************************/
/********************************************************************************************************************************************************************************/


void setup() {
  
  // make the background
  background(248);
  size(1600, 960);
  
  // set the text font
  textFont(createFont(PFont.list()[4], 30));
  
  
  // start oscP5, listening for incoming messages at port 9001 
  oscP5 = new OscP5(this, server_port);
  
  // set remote location to receive data
  myRemoteLocation = new NetAddress(ip, client_port);
    
  // audio pre-configuration
  minim = new Minim(this);  
  in = minim.getLineIn(Minim.STEREO, 480);
  
  // get the webcam
  String[] cameras = Capture.list();
  
  if(cam == null){
    cam = new Capture(this, cameras[0]);
  }
  
  update_notices();
    
  for( int i = 0; i < 100; i++){
    stroke(map(i,0,100,160,210),0,0);
    line(0,i,1600,i);
  }
    
  // set the title
  fill(255); 
  text("Instalação Tecnológica Leiamídia", 560 , 70); 
  
  // set the image and text in the middle content
  img = loadImage(crawler_path + "images/g1.png");
  img.resize(0, 130);
  image(img, 690, 180);
  fill(195,0,0); 
  //text("      O portal de notícias da globo", 500 , 335);
  
  textFont(createFont(PFont.list()[2], 20));
  
  fill(100);
  text("Escolha uma notícia, faremos uma análise sua!", 575 , 345);  
  
  fill(60);
  line(30,390,1560,390);
  
  
  textFont(createFont(PFont.list()[2], 30));
  
  img = loadImage("./images/leiamidia_icon_white.png");
  img.resize(0, 80);
  image(img, 1460, 10);
  image(img, 20, 10);
  
  line(0, 90, 1600, 90);
 
  
  // make notices rect's and format notices titles
  for (int i = 0; i < titles.size(); i++) {
  
    // make the notice title rect
    rectOver.add(i, false);
    rectX.add(i, 260);
    rectY.add(440 + ( 210 * i ) );
    
    // format legend titles to show below the webcam
    legend_titles = legend_titles + titles.get(i) + "                 ";
    
    // print notice image
    img = loadImage(crawler_path + "images/" + image_urls.get(i).split("/")[image_urls.get(i).split("/").length-1]);
    img.resize(0, 150);
    image(img, 30, 440 + ( 210 * i ) );
    
    String format_description = "";
    int break_line = 150;
    for( int j = 0; j < descriptions.get(i).length() / break_line; j++){
      format_description = format_description + descriptions.get(i).substring(j * break_line, j * break_line + break_line) + "\n";
    }
    format_description = format_description + descriptions.get(i).substring((descriptions.get(i).length() / break_line) * break_line, descriptions.get(i).length()) + "\n";
    descriptions.set(i,format_description);
  }
  
  // start rect of notices colors
  rectColor = color(255);
  rectHighlight = color(230);
  baseColor = color(255);
  currentColor = baseColor;
  
  button_restart_color_up = color(255);
  button_restart_color_down = color(0);
  
  time_record = 0;
  time_legend = 0;
  time_notice_update = 0;
  sound_rec_count = 0;
}



/********************************************************************************************************************************************************************************/
/************************************************************************************** DRAW ************************************************************************************/
/********************************************************************************************************************************************************************************/


void draw() {
  
  time_notice_update++;
  if(time_notice_update == update_notices_delay){
    
    update_notices();
  
    time_notice_update = 0;
    
  }
  
  // if we are in the first page...
  if(current_page.equals(true)){
    
    // update to see if mouse is on notice rect
    update_notice_rects();
  
  }
  
  // if we are in the second page...
  else {    
    
    // count the time of record
    time_record ++;
    
    // if delay_time is done, starts recording...
    if( time_record == audio_record_start_delay ) {
      sound_rec_count = listFiles(sound_path).length + 1;
      // starts recorder
      println("starting recording audio...");
      recorder = minim.createRecorder(in, "sounds/" + sound_rec_count + ".wav");
      recorder.beginRecord();
      
    }
    // if passed record_speed time, stop the record
    else if ( time_record == audio_record_start_delay + record_speed ){
      
      // stops the recorder and save the .wav
      System.out.println("audio captured (" + sound_rec_count + ".wav)!");
      recorder.save();
      recorder.endRecord();
      delay(10);
      // send the name of the audio saved via OSC
      OscMessage myMessage = new OscMessage("/fileName");
      
      String msg_string = sound_rec_count + ".wav";
      
      myMessage.add(msg_string); 
      oscP5.send(myMessage, myRemoteLocation); 
      
      println("OSC msg sended: ", msg_string);
      
      // reset time_record
      time_record = audio_record_start_delay - 10;
    }
    
    
    // make restart button
    button_restart_mouse_over = false;
    button_restart_x = 1470;
    button_restart_y = 900;
    
    update_restart_button();
    
    // check if received OSC msg to print predictions
    if(flagOscReceived == true){
      
      reset_webcam_effects = false;
      
      // make the prediction circle with the triangle of predictions
      make_prediction_circle();
      
      // make the prediction rect
      make_prediction_rect();
    
      // reset the flag to wait another msg
      flagOscReceived = false;
      
    }
    
    // update the webcam frame
    if (cam.available() == true) {
      cam.read();
    }
    
    // function to apply the effects on the webcam frame
    apply_webcam_effects();
    
    // print webcam frame
    image(cam,945,120);
      
    // update the legend below the webcam  
    update_legend();
      
  }
  
}
 
 

/********************************************************************************************************************************************************************************/
/************************************************************************************ FUNCTIONS *********************************************************************************/
/********************************************************************************************************************************************************************************/



/* this function activate by receiving OSC msg */
void oscEvent(OscMessage theOscMessage) {
  
  // if OSC message tag is prediction 
  if(theOscMessage.addrPattern().equals("/prediction")){
    
    // print the msg
    println("### received an osc message with addrpattern "+theOscMessage.addrPattern()+" and typetag "+theOscMessage.typetag() +" and value "+theOscMessage.get(0).toString());
    
    // split msg received based on pattern: predictionName-%ofFear-%ofHappy-%ofSad
    String oscMsg = theOscMessage.get(0).toString();
    String[] oscMsgSplit = oscMsg.split("-", 7);
    
    lastEmotion = oscMsgSplit[0];
    lastFearPercent = oscMsgSplit[1];
    lastHappyPercent = oscMsgSplit[2];
    lastSadPercent = oscMsgSplit[3];
    flagOscReceived = true;
    
  }
}


/* function to get columns of json/notice file (authors, title, description...) */
ArrayList<String> getJsonColumn (JSONObject obj, String column_name){

  ArrayList<String> column = new ArrayList<String>();
  
  // getting address 
  Map address = ((Map)obj.get(column_name)); 
    
  // iterating address Map 
  Iterator<Map.Entry> itr1 = address.entrySet().iterator(); 
  while (itr1.hasNext()) { 
      Map.Entry pair = itr1.next(); 
      column.add(pair.getValue().toString()); 
  } 
  
  return column;
  
}


/* function to apply 3 different image filters based on emotion prediction */
void apply_webcam_effects(){
  
    // load pixels to apply effects
    loadPixels();
    cam.loadPixels();
    
    // make the fear effect.
    if(lastEmotion.equals("fear") && !reset_webcam_effects){
      
      // change rgb values for each pixel and show a circle of the image based on mouse position, adjusting the brightness
      for (int x = 0; x < cam.width; x++) {    
        for (int y = 0; y < cam.height; y++) {      
          // Calculate the 1D location from a 2D grid
          int loc = x + y * cam.width;      
        
          // Get the red, green, blue values from a pixel      
          float r = red  (cam.pixels[loc]);      
          float g = green(cam.pixels[loc]);      
          float b = blue (cam.pixels[loc]/2);      
          
          // Calculate an amount to change brightness based on proximity to the mouse      
          float d = dist(x+945, y+160, mouseX, mouseY);      
          float adjustbrightness = map(d, 8, 200, 8, 1);      
          r *= adjustbrightness;      
          g *= adjustbrightness;      
          b *= adjustbrightness;      
          
          // Constrain RGB to make sure they are within 0-255 color range      
          r = constrain(r, 0, 255);      
          g = constrain(g, 0, 255)/2;      
          b = constrain(b, 0, 255);      
        
          // Make a new color and set pixel in the window      
          color c = color(r, g, b);      
          cam.pixels[loc] = c;    
        }  
      }
      
    // make happy effect.
    } else if(lastEmotion.equals("happy") && !reset_webcam_effects){
      
      // multiply all pixels, that are higher than 10000000, by 4
      for (int x = 0; x < cam.width; x++) {    
        for (int y = 0; y < cam.height; y++) {      
          // Calculate the 1D location from a 2D grid
          int loc = x + y * cam.width;      
          if(cam.pixels[loc]>-10000000){
            cam.pixels[loc] = cam.pixels[loc] * 4/ 1;   
          } 
        }  
      } 
      
    // make sad effect.
    } else if(lastEmotion.equals("sad") && !reset_webcam_effects){
      
      int filterationSize = 12;
  
      // change image matrix pixels based on filter/window size
      for ( int tile_y = 0; tile_y < cam.width; tile_y ++ ) {
          for ( int tile_x = 0; tile_x < cam.height; tile_x ++ ) {
  
              int start_x = tile_x*filterationSize;
              int start_y = tile_y*filterationSize;
              int end_x   = min(start_x+filterationSize,cam.width); 
              int end_y   = min(start_y+filterationSize, cam.height);
              int size    = (end_x-start_x) * (end_y-start_y);
  
              float r = 0, g = 0, b = 0;
              for (int by = start_y; by < end_y; by++ ) {
                  for (int bx = start_x; bx < end_x; bx++ ) {
                      int p = by * cam.width + bx;
                      r += red(this.cam.pixels[p])   / size;
                      g += green(this.cam.pixels[p]) / size;
                      b += blue(this.cam.pixels[p])  / size;
                  }
              }
  
              for (int by = start_y; by < end_y; by++ ) {
                  for (int bx = start_x; bx < end_x; bx++ ) {
                      int p = by * cam.width + bx;
                      this.cam.pixels[p] = color(r/2, g/2, b);
                  }
              }
          }
      }
    
    }
    
    // update pixels and print the webcam frame
    updatePixels();
    
}


/* make the circle of prediction and the triangle based on each % of emotion prediction */
void make_prediction_circle(){
  
    // change text font
    textFont(createFont(PFont.list()[10], 22));
    
    // content gray of predictions
    fill(230);
    noStroke();
    rect(950, 670, 630, 275, 7);
    stroke(0);
    
    // print circle of predictions
    fill(256, 0, 0);
    text("Fear", 1170, 860);  
    fill(0, 200, 0);
    text("  Happy", 1055, 715);  
    fill(0, 0, 256);
    text("Sad", 990, 860);  
    
    stroke(80);
    fill(240);
    circle(1100, 800, 140);
    stroke(205);
    fill(235);
    circle(1100, 800, 125);
    fill(230);
    circle(1100, 800, 110);
    fill(225);
    circle(1100, 800, 95);
    fill(220);
    circle(1100, 800, 80);
    fill(215);
    circle(1100, 800, 65);
    fill(210);
    circle(1100, 800, 50);
    fill(205);
    circle(1100, 800, 35);
    fill(200);
    circle(1100, 800, 20);
    fill(195);
    circle(1100, 800, 5);
    
    fill(80);
    stroke(0);
    circle(1100, 800, 1);
  
    Float sadPercent = Float.parseFloat(lastSadPercent) * 0.01 ;
    Float fearPercent = Float.parseFloat(lastFearPercent) * 0.01 ;
    Float happyPercent = Float.parseFloat(lastHappyPercent) * 0.01 ;
      
    if(lastEmotion.equals("fear")){
      
      // put red color for fear, based on its % of classification
      fill(256 * fearPercent, 0, 0);
      
    } else if(lastEmotion.equals("happy")){
      
      // put green color for happy, based on its % of classification
      fill(0, 256 * happyPercent, 0);
      
    } else if(lastEmotion.equals("sad")){
      
      // put blue color for sad, based on its % of classification
      fill(0, 0, 256 * sadPercent);
      
    }
    
    // make the triangle of predictions
    triangle(1100 - (70 * sadPercent), 800 + (45 * sadPercent),
            1100 + (70 * fearPercent), 800 + (45 * fearPercent),
            1100, 800 - (70 * happyPercent));
            
}


/* function to print the rect of predictions information */
void make_prediction_rect(){
  
    // change text font
    textFont(createFont(PFont.list()[2], 20));
    
    // print rect of predictions
    fill(220);
    noStroke();
    rect(1310, 710, 240, 150, 7);
    stroke(0);
    
    fill(50);
    text(" Your emotion is: " + lastEmotion + "!", 1320, 740); 
    line(1320, 751, 1540, 751);
    text("        Fear:      " + lastFearPercent + "%", 1285, 790); 
    text("        Happy:   " + lastHappyPercent + "%", 1285, 815); 
    text("        Sad:       " + lastSadPercent + "%", 1285, 840); 
    
}


/* function to slice/reprint the legend each time that it's called */
void update_legend(){
  
    // make the legend red rect
    noStroke();
    fill(195,0,0);
    rect(945, 600, 639, 50);
    stroke(0);
    
    // change text font
    textFont(createFont(PFont.list()[2], 25));
    
    // make the white legend of notices
    fill(255);
    text(legend_titles, 1030, 630); 
    
    // update the time_legend and move the legend by removing one char
    time_legend++;
    if(time_legend == legend_speed){
      legend_titles = legend_titles.substring(1); 
      time_legend = 0;
    } 
    
    // rect to filter the legend text
    fill(240);
    noStroke();
    rect(1580, 610, 30, 30);
    fill(195,0,0);
    rect(1580, 610, 10, 30);
    stroke(0);
    
    // change text
    stroke(0);
    textFont(createFont(PFont.list()[2], 20));
      
    // put the red legend g1 logo
    noTint();
    img = loadImage(crawler_path + "images/g1_mini_logo.png");
    img.resize(0, 45);
    image(img, 948, 603);
    
}


/* function to update restart button and change color when mouse is over it */
void update_restart_button() {
  
  //if mouse is over the button...
  if ( overRect(button_restart_x, button_restart_y, 30, 70) ) {
    button_restart_mouse_over = true;
  } else {
    button_restart_mouse_over = false;
  }
  
  // highlight the button if mouse is on
  if (button_restart_mouse_over) {
    fill(button_restart_color_up);
  } else {
    fill(button_restart_color_down);
  }

  // change text font
  textFont(createFont(PFont.list()[4], 20));
  
  // print the button
  stroke(0);
  fill(180,17,17);
  rect(button_restart_x - 15, button_restart_y, 95, 30, 7);
  
  fill(255);
  text(" Back", button_restart_x + 15, button_restart_y + 22 );  
  
  stroke(0);

  img = loadImage("./images/back_icon.png");
  img.resize(0, 20);
  image(img, 1460, 907);
    
  // change text font
  textFont(createFont(PFont.list()[2], 30));
}


/* function to update notices rect, to change rect color when mouse is over it */
void update_notice_rects() {
  
  for(int i = 0; i < titles.size(); i++){
    
    //i f mouse is over the rect...
    if ( overRect(rectX.get(i), rectY.get(i), rect_size_x, rect_size_y) ) {
      
      // set true to it
      rectOver.set(i, true);
      
      // set false to others
      for(int j = 0; j < titles.size(); j++){
        if( rectOver.get(j).equals(true) && i != j ) {
          rectOver.set(j, false);
          break;
        }
      }
    } else {
      rectOver.set(i, false);
    }
  }
    
  // highlight the notice that mouse is on
  for(int i = 0; i < titles.size(); i++){
    
    // set the rect colors: gray for the mouse-on notice and white for others
    if (rectOver.get(i)) {
      fill(rectHighlight);
    } else {
      fill(rectColor);
    }
    
    // change the fontrectX
    textFont(createFont(PFont.list()[4], 23));
    
    // print the rects
    stroke(255);
    rect(rectX.get(i), rectY.get(i), rect_size_x, rect_size_y,7);
    
    // print the red circle of each notice
    //fill(200,0,0); 
    //stroke(200,0,0);
    //circle(277, 500 + ( 200 * i ), 5);  
    
    // print the notice titles
    fill(195,0,0);
    text(titles.get(i), 290, 480 + ( 210 * i));
    
    stroke(200,0,0);
    line(290, 490 +  ( 210 * i ),  290 + 1240, 490 + ( 210 * i ));
    
    // change the fontrectX
    textFont(createFont(PFont.list()[2], 18));
    // print the notice descriptions
    fill(80);
    text(descriptions.get(i), 290, 530 + ( 210 * i ) );
    
  }
    
}


/* function to check if mouse is over the rect */
boolean overRect(int x, int y, int width, int height)  {
  
  if (mouseX >= x && mouseX <= x+width && mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
  
}


/* function to read json file updating the notices */
void update_notices(){
  
  // pick all notices from json file
   try{
    // get json objetct
    Object obj = new JSONParser().parse(new FileReader(crawler_path + "data_saved/notices_info.json"));
    
    // typecasting obj to JSONObject 
    JSONObject jo = (JSONObject) obj; 
    
    // get information 
    titles = getJsonColumn(jo, "title"); 
    descriptions = getJsonColumn(jo, "description"); 
    date_publishs = getJsonColumn(jo, "date_publish"); 
    image_urls = getJsonColumn(jo, "image_url");
    maintexts = getJsonColumn(jo, "maintext");
    
  }catch (Exception e) {
    println("error in json file!");
  }
  
  // load notice images
  for (int i = 0; i < titles.size(); i++) {
    // get the images of notices
    String image_name = image_urls.get(i).split("/")[image_urls.get(i).split("/").length-1];
    File notice_image = new File (crawler_path + "images/" + image_name);
    
    if(!notice_image.exists()){
      try{
        InputStream in = new URL(image_urls.get(i)).openStream();
        Files.copy(in, Paths.get(crawler_path + "images/" + image_name));
      } catch (Exception e){
        println("Error in download the notice images");
      }
    }
  }
  
  SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");  
  println("Notices updated sucessfull ( "+ formatter.format(new Date()) +" )!");
    
}


/* this function is called everytime that mouse clicks */
void mousePressed() {
  
  // if we are in the first page...
  if(current_page.equals(true)){
    // for each notice title...
    for(int i = 0; i < titles.size(); i++){
      
      // if is the rect clicked...
      if (rectOver.get(i)) {
        
        // update the current page
        current_page = false;
        
        // reprint a blank page in content
        fill(255);
        rect(0, 100, 1600, 950);
        
        
        // set the text font
        textFont(createFont(PFont.list()[4], 25));  
        fill(195,0,0);
        text(titles.get(i), 170, 450 , 650, 650);
        
            
        // change the font
        textFont(createFont(PFont.list()[2], 19));
        fill(90);
        
        // print notice description
        text(maintexts.get(i), 20, 560, 890, 500 );
        
        strokeWeight(3);
        stroke(195,0,0);
        rect(258, 148, 408, 273, 7);
        strokeWeight(1);
        
        // print notice image
        String img_directory = crawler_path + "images/" + image_urls.get(i).split("/")[image_urls.get(i).split("/").length-1];
        img = loadImage(img_directory);
        img.resize(0, 270);
        image(img, 260, 150 );
        
        // print the gray content for webcam analyzes
        fill(240);
        rect(926, 100, 926, 960);
        
        strokeWeight(10);
        stroke(195,0,0);
        rect(945, 120, 639, 530, 7);
        strokeWeight(1);
        
        // reformat the font
        textFont(createFont(PFont.list()[2], 30));
        
        // start webcam
        cam.start(); 
        
      }
    }
    
  }
  else{
    // if is the rect clicked...
    if (button_restart_mouse_over) {
      
      // update the current page
      current_page = true;
      
      if ( recorder!= null && recorder.isRecording() ){
        
        // stops the recorder and save the .wav
        System.out.println("audio capture interrupt! saving part of sound" + (listFiles(sound_path).length + 1) + ".wav)!");
        recorder.save();
        recorder.endRecord();
        
      }
    
      // reset webcam effects
      reset_webcam_effects = true;
    
      // reset time_record
      time_record = 0;
      
      // restart system and variables
      setup();
      
    }
  }
}
