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
int rectSize = 1600;     // Diameter of rect
color rectColor, baseColor;
color rectHighlight;
color currentColor;
ArrayList<Boolean> rectOver = new ArrayList<Boolean>();

// to make restart button
Integer button_restart_x; 
Integer button_restart_y;      
int button_size = 60;     // Diameter of rect
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
  background(255);
  size(1600, 960);
  
  // set the text font
  textFont(createFont(PFont.list()[0], 30));
  
  
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
    
  // set the title
  fill(0); 
  text("Escolha uma notícia, faremos uma análise sua!", 450 , 90); 
  
  // set the image and text in the middle content
  img = loadImage(crawler_path + "images/g1.png");
  img.resize(0, 120);
  image(img, 720, 180);
  text("      O portal de notícias da globo", 500 , 320);
  
  textFont(createFont(PFont.list()[0], 22));
  
  text("By: João Teixeira Araújo", 650 , 125);  
  
  fill(120);
  text("           Notícias atualizadas em tempo real!", 500 , 352);  
  
  textFont(createFont(PFont.list()[0], 30));
  
  img = loadImage("./images/leiamidia_icon.png");
  img.resize(0, 100);
  image(img, 1405, 20);
  image(img, 20, 20);
  
  line(0, 140, 1600, 140);
 
  
  // make notices rect's and format notices titles
  for (int i = 0; i < titles.size(); i++) {
  
    // make the notice title rect
    rectOver.add(i, false);
    rectX.add(i, 0);
    rectY.add(430 + ( 80 * i ) );
    
    // format legend titles to show below the webcam
    legend_titles = legend_titles + titles.get(i) + "                 ";
    
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
    button_restart_x = 1500;
    button_restart_y = 870;
    
    update_restart_button();
    
    // check if received OSC msg to print predictions
    if(flagOscReceived == true){
      
      reset_webcam_effects = false;
      
      // make the prediction rect
      make_prediction_rect();
      
      // make the prediction circle with the triangle of predictions
      make_prediction_circle();
    
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
    image(cam,945,160);
      
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
    textFont(createFont(PFont.list()[0], 30));
    
    // print circle of predictions
    fill(256, 0, 0);
    text("Fear", 1190, 890);  
    fill(0, 200, 0);
    text("Happy", 1055, 695);  
    fill(0, 0, 256);
    text("Sad", 955, 890);  
    
    fill(255);
    circle(1100, 815, 200);
    circle(1100, 815, 150);
    circle(1100, 815, 100);
    circle(1100, 815, 50);
  
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
    triangle(1100 - (80 * sadPercent), 815 + (60 * sadPercent),
            1100 + (80 * fearPercent), 815 + (60 * fearPercent),
            1100, 815 - (100 * happyPercent));
            
}


/* function to print the rect of predictions information */
void make_prediction_rect(){
  
    // change text font
    textFont(createFont(PFont.list()[0], 20));
    
    // print rect of predictions
    fill(255);
    rect(1300, 700, 240, 130);
    
    fill(50);
    text("      Your emotion is: " + lastEmotion + "!", 1260, 730); 
    text("          -----------------------------", 1220, 745); 
    text("           Fear:     " + lastFearPercent + "%", 1235, 770); 
    text("           Happy:   " + lastHappyPercent + "%", 1235, 790); 
    text("           Sad:      " + lastSadPercent + "%", 1235, 810); 
    
}


/* function to slice/reprint the legend each time that it's called */
void update_legend(){
  
    // make the legend red rect
    fill(170,0,0);
    rect(945, 600, 639, 50);
    
    // change text font
    textFont(createFont(PFont.list()[0], 25));
    
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
    fill(200);
    stroke(200);
    rect(1585, 610, 30, 30);
    
    // change text
    stroke(0);
    textFont(createFont(PFont.list()[0], 20));
      
    // put the red legend g1 logo
    noTint();
    img = loadImage(crawler_path + "images/g1_mini_logo.png");
    img.resize(0, 45);
    image(img, 948, 603);
    
}


/* function to update restart button and change color when mouse is over it */
void update_restart_button() {
  
  //if mouse is over the button...
  if ( overRect(button_restart_x, button_restart_y, button_size, button_size) ) {
    button_restart_mouse_over = true;
  } else {
    button_restart_mouse_over = false;
  }
  
  
  // print restart text
  fill(200);
  stroke(200);
  rect(button_restart_x, button_restart_y - 25, 100, 200 );
    
    
  // highlight the button if mouse is on
  if (button_restart_mouse_over) {
    fill(button_restart_color_up);
  } else {
    fill(button_restart_color_down);
  }

  // change text font
  textFont(createFont(PFont.list()[0], 20));
  
  // print the button
  stroke(0);
  fill(150,17,17);
  rect(button_restart_x, button_restart_y, button_size, button_size);
  
  fill(0);
  text(" Back", button_restart_x - 3, button_restart_y - 5 );  
  
  stroke(0);

  img = loadImage("./images/back_icon.png");
  img.resize(0, 45);
  image(img, 1505, 880);
    
  // change text font
  textFont(createFont(PFont.list()[0], 30));
}


/* function to update notices rect, to change rect color when mouse is over it */
void update_notice_rects() {
  
  for(int i = 0; i < titles.size(); i++){
    
    //i f mouse is over the rect...
    if ( overRect(rectX.get(i), rectY.get(i), rectSize, rectSize) ) {
      
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
    
    // print the rects
    stroke(0);
    rect(rectX.get(i), rectY.get(i), rectSize, rectSize);
    
    // print the red circle of each notice
    fill(200,0,0); 
    circle(20, 470 + ( 80 * i ), 20);  
    
    // print the notice titles
    fill(0);
    text(titles.get(i), 50, 480 + ( 80 * i ) );
    
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
        
        // reprint a blank page in title
        fill(255);
        rect(0, 141, 1600, 950);
        
        // reprint a blank page in content    
        fill(255);
        stroke(255);
        rect(220, 0, 1600, 138);
        stroke(0);
        
        // print the notice title
        fill(0);
        text(titles.get(i), 230, 80 );
            
        // change the font
        textFont(createFont(PFont.list()[0], 22));
        
        // print notice description
        text(maintexts.get(i), 20, 420, 880, 500 );
        
        // print notice image
        String img_directory = crawler_path + "images/" + image_urls.get(i).split("/")[image_urls.get(i).split("/").length-1];
        img = loadImage(img_directory);
        img.resize(0, 240);
        image(img, 215, 160 );
        
        // print the gray content for webcam analyzes
        fill(200);
        rect(926, 141, 926, 960);
        
        // print the division content line
        fill(0);
        stroke(0);
        line(925, 141, 925, 960);
        
        // reformat the font
        textFont(createFont(PFont.list()[0], 30));
        
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
      
      if ( recorder.isRecording() ){
        
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
