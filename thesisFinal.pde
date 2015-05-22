
//several potential problems:
// OK -  1 - my logic on null and omit skips has an issue, especially if its in the "currentLevel" slot and not just skipping on its way towards it. probably a problem, yes.
// meh - 2 - it does an extra path search more than necessary during a normal "pull back".
// meh - 3 - in the last stage it resets all to zero while pulling back, apparently. not necessary to happen.
// OK - 4 - this stuff is still all too huge. need to cull more. or cull random sections? or have a small edgeLimit but always add a random number to the offset?
// NO. too much to try to figure out. 5 - possibly download the conceptnet locally. no http requests means potentially much much faster.
// OK  - 6 - there is definitely a bug that causes a loop sometimes. i suspect an omit or null near the first level and its repeat point (EDIT - not the first level, maybe any level on a pullback)
//8 - try the IsA relation search as a starting point. generate a specific secondPath to start with outside of the normal random offset.
// not going to bother with the truly systematic search.  9 - save current state to disk and load on run (including decrementing boolean) - then use that to pre-generate a ton.
//10 - try increasing edgelimit per level of recursion. (edgeLimit array {1,1,1,1,2,3,4,5} etc. (and combine with the random offset - large for first edges, smaller for later))
//11 - i GUESS try to cull all previously checked nodes again? just to check?
// not necessary with small randomer seachers.  12 - can also cull completely arbitrary nodes at various levels of recursion. 

// clean out any paths that have "money" in the middle of them/
// i might have some buggy paths.

import ddf.minim.*;
import ddf.minim.ugens.*;

import processing.serial.*;

Minim minim;
AudioOutput out;
Oscil wave;

float soundFreq = 1000;

Serial port;
int stepper = 0;
//String textToSend = "";
int mode = -1;

boolean active = true;
boolean cleared = false;

int refreshSpeed = 1;

final int edgeLimit = 2;
final int levelLimit = 13;
final int howManyEdges = 100;

final int[] edgeLimits = {
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 5
};
//final int[] edgeRandonOffset = {50,45,40,35,30,25,20,15,10,5,4,3,2,1};

final String path = "http://conceptnet5.media.mit.edu/data/5.2";

JSONObject json;

int[] offsetArray = new int[levelLimit];
char[] offsetChar = new char[levelLimit]; //just to test
int whichToIncr = 0; // for testing above
boolean decrementing = false; 

int totalPaths = 0;
int totalSuccesses = 0;
int totalRecurses = 0;
int totalOmits = 0;
int totalNulls = 0;

String firstPath = "/c/en/person";
String nextPath = firstPath;

String[] prevPaths = new String[levelLimit]; 
String[] prevNames = new String[levelLimit];

//ArrayList<String[]> successPaths;
ArrayList<String[]> successNames;

boolean done = false;
boolean exception = false;

String[] loggedSuccesses;

String displayedSuccess = "test";
String[] displayedSuccessArray; 

void setup() {
  size(200, 500);

  println(Serial.list());
  println();
  port = new Serial(this, Serial.list()[3], 9600);
  port.bufferUntil('\n');
  clearAllLCDs();
  background(250);
  //frameRate(1);
  prepareExitHandler();
  //successPaths = new ArrayList<String[]>();
  successNames = new ArrayList<String[]>();

  loggedSuccesses = loadStrings("successes.txt");

  for (int i = 0; i < levelLimit; i++) {
    offsetArray[i] = 0;
    offsetChar[i] = 'O';
    prevPaths[i] = "";
    prevNames[i] = "";
  }
  textAlign(LEFT, CENTER);

  displayedSuccessArray = changeDisplaySuccess();

  minim = new Minim(this);
  out = minim.getLineOut();
  wave = new Oscil(440, 0.0, Waves.SINE);
  wave.patch(out);
}

public void serialEvent(Serial myPort) {
  String receivedString = myPort.readStringUntil('\n');
  println("received: "+receivedString);
}

public void clearAllLCDs() {
  port.write('>');
  stepper = 0;
  if (wave != null) {
    wave.setAmplitude(0.0);
  }
  soundFreq = random(1000);
  delay(2000);
} 


public void sendData(String textToSend) {
  char[] characters = textToSend.toCharArray(); 

  stepper++;

  for (int i=0; i < characters.length; i++) {
    port.write(characters[i]);
    delay(10);
  }
  port.write('\r');
} 

void draw() {
  background(250);
  fill(0);

  if (mode == 1) {

    if (displayedSuccessArray != null) {
      for (int i = 0; i < displayedSuccessArray.length; i++) {
        text(displayedSuccessArray[i], 15, 60 + i*20);
      }

      if (frameCount % 15 == 0) {
      //if (frameCount % refreshSpeed == 0) {
        println(stepper);
        if (!displayedSuccessArray[stepper].equals("")) {
          wave.setAmplitude(0.05);
          wave.setFrequency(random(soundFreq, soundFreq+500)+stepper*random(1,5));
        }
        sendData(displayedSuccessArray[stepper]);
      } else {
        wave.setAmplitude(0.0);
      }
    }

    if (stepper > displayedSuccessArray.length - 1) {
      delay(500);
      wave.setAmplitude(0.0);
      delay(5000);
      displayedSuccessArray = changeDisplaySuccess();
      refreshSpeed = (int)random(10)+1;
      clearAllLCDs();
      mode = -mode;
    }
  } else if (mode == -1) {
    for (int i = 0; i < (int)random(32); i++) {
      port.write(char(-1));
    }
    port.write('\r');
    delay(10);
    stepper++;
    if (stepper > 15) {
      delay(1000);
      clearAllLCDs();
      mode = -mode;
    }
  }


  if (done == false) {
    if (frameCount % 100 == 0) {
      saveStatus();
    }
    recurseDown(levelLimit-1);
  } else {
    saveStatus();
    println("delaying");
    delay(1000);
    done = false;
  }
}

private String[] changeDisplaySuccess() {
  int whichSuccess = (int)random(loggedSuccesses.length);
  //println(loggedSuccesses[whichSuccess]);
  displayedSuccess = loggedSuccesses[whichSuccess];
  String[] dsa = split(displayedSuccess, ',');
  return dsa;
}


// must add "prepareExitHandler();" in setup() for Processing sketches 
private void prepareExitHandler() {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      //System.out.println("SHUTDOWN HOOK");
      saveStatus();
      try {
        stop();
      } 
      catch (Exception ex) {
        ex.printStackTrace(); // not much else to do at this point
      }
    }
  }
  ));
}  


public void recurseDown(int currentLevel) {
  totalRecurses++;

  //----------------------------------------------------------------------
  //finish conditions and actions-----------------------------------------
  //----------------------------------------------------------------------
  if (currentLevel < 0) {
    println("done");
    println("total successes: " + totalSuccesses);
    println("total paths: " + totalPaths);
    println("total recurses: " + totalRecurses);
    println("total omits: " + totalOmits);
    println("total nulls: " + totalNulls);

    //    for (int i = 0; i < successPaths.size (); i++) {
    //      String[] thisPath = successPaths.get(i);
    //      println();
    //      print("c/en/person -> ");
    //      for (int j = 0; j < thisPath.length; j++) {
    //        print(thisPath[j] + " -> ");
    //      }
    //      println();
    //    }

    for (int i = 0; i < successNames.size (); i++) {
      String[] thisName = successNames.get(i);
      println();
      print("c/en/person -> ");
      for (int j = 0; j < thisName.length; j++) {
        print(thisName[j] + " -> ");
      }
      println();
    }

    done = true; 
    return;
  }

  //----------------------------------------------------------------------
  //array prints----------------------------------------------------------
  //----------------------------------------------------------------------
  print("offset array: ");
  for (int i = 0; i < offsetArray.length; i++) {
    print(offsetArray[i]+ " - ");
  }
  println();

  print("whichToIncr:  ");
  for (int i = 0; i < offsetChar.length; i++) {
    if (whichToIncr == i) {
      print("X - ");
    } else {
      print("O - ");
    }
  }
  println();

  print("currentLevel: ");
  for (int i = 0; i < offsetChar.length; i++) {
    if (currentLevel == i) {
      print("! - ");
    } else {
      print(". - ");
    }
  }
  println();

  //  print("search chain: " + firstPath + " --> ");
  //  for (int i = 0; i < whichToIncr; i++) {
  //    print(prevPaths[i] + " - ");
  //  }
  //  println();

  //----------------------------------------------------------------------
  //searching next path---------------------------------------------------
  //----------------------------------------------------------------------
  print("searching: " + nextPath + ", ");
  Edge newEdge = getEdgeOf(false, "", "", nextPath, offsetArray[whichToIncr] + (int)random(howManyEdges), 1);

  //----------------------------------------------------------------------
  //if new edge is null,--------------------------------------------------
  //----------------------------------------------------------------------
  if (newEdge == null && exception == false) {
    totalNulls++;
    println("found: NULL!!");
    println();

    offsetArray[whichToIncr] = 0;
    if (whichToIncr > 0) {
      whichToIncr--;
      if (whichToIncr > 0) {
        nextPath = prevPaths[whichToIncr-1];
      } else {
        nextPath = firstPath;
      }
    }
    if (whichToIncr == levelLimit - 1) {
      println("whichToIncr == levelLimit, recursing and decrementing");
      println();
      decrementing = true;
      recurseDown(currentLevel);
    } else {
      println("recursing on whichToIncr");
      println();
      decrementing = true;
      recurseDown(whichToIncr);
    }

    //----------------------------------------------------------------------
    //if i catch a HTTP rejection-------------------------------------------
    //----------------------------------------------------------------------
  } else if (newEdge == null && exception == true) {
    println("returning, exception registered");
    exception = false;
    //delay(1000);
    return;

    //----------------------------------------------------------------------
    //if new edge is to be omitted,-----------------------------------------
    //----------------------------------------------------------------------
  } else if (newEdge.omit == true) {    //should it be omitted?
    totalOmits++;
    print("found: " + newEdge.finalPath + " - OMIT - ");

    if (offsetArray[whichToIncr] < (/*edgeLimit*/edgeLimits[whichToIncr] - 1)) { 
      println("current position is below edge limit, increment.");
      println();
      offsetArray[whichToIncr]++;  //increment offset at current level position
      //nextPath doesn't change, uses current one, just changes offset
    } else {
      println("current position is at edge limit, set it to 0 and decrease whichToIncr");

      offsetArray[whichToIncr] = 0;
      if (whichToIncr > 0) {
        whichToIncr--;
        if (whichToIncr > 0) {
          nextPath = prevPaths[whichToIncr-1];
        } else {
          nextPath = firstPath;
        }
      }
      if (whichToIncr == levelLimit - 1) {
        println("whichToIncr == levelLimit, recursing and decrementing");
        println();
        decrementing = true;
        recurseDown(currentLevel);
        //      } else if (whichToIncr == 0) {
        //        println("uh oh");
        //        println();
        //!!!!!
        ///NEED A FIX HERE, AND ABOVE
        //!!!!!
      } else {
        println("recursing on whichToIncr");
        println();
        decrementing = true;
        recurseDown(whichToIncr);
      }
    }

    //----------------------------------------------------------------------
    //normal case, proceed---------------------------------------------------
    //----------------------------------------------------------------------
  } else {
    println("found: " + newEdge.finalPath);
    prevPaths[whichToIncr] = newEdge.finalPath;
    prevNames[whichToIncr] = newEdge.finalName;
    for (int i = 0; i < prevPaths.length-1; i++) {
      if (prevPaths[i].contains("money") && prevPaths[i+1].equals("")) {
        //String[] successPath = new String[i+1];
        String[] successName = new String[i+1];
        for (int j = 0; j < successName.length; j++) {
          //successPath[j] = prevPaths[j];
          successName[j] = prevNames[j];
        }
        //successPaths.add(successPath);
        successNames.add(successName);
        totalSuccesses++;
      }
    }
    if (prevPaths[prevPaths.length-1].contains("money")) {
      //String[] successPath = new String[prevPaths.length];
      String[] successName = new String[prevNames.length];
      for (int j = 0; j < successName.length; j++) {
        //successPath[j] = prevPaths[j];
        successName[j] = prevNames[j];
      }
      //successPaths.add(successPath);
      successNames.add(successName);
      totalSuccesses++;
    }
    //successPaths.add(prevPaths.clone());
    totalPaths++;

    print("current chain: " + firstPath + " --> ");
    for (int i = 0; i < whichToIncr; i++) {
      print(prevPaths[i] + " - ");
    }
    print(newEdge.finalPath);
    println();


    print("current name chain: " + firstPath + " --> ");
    for (int i = 0; i < whichToIncr; i++) {
      print(prevNames[i] + " - ");
    }
    print(newEdge.finalName);
    println();
    println();


    //increment index is lower than level limit and not decrementing - increment it-----------
    //----------------------------------------------------------------------------------------
    if (whichToIncr < (levelLimit - 1) && decrementing == false) {
      println("current position level is below max level number, increment.");
      whichToIncr++;  //increment level position to increment if its lower than level limit and not decrementing
      nextPath = newEdge.finalPath;    //update nextPath to go a level deeper
      return;
    }
    if (decrementing == true) {
      decrementing = false;
    }

    if (offsetArray[currentLevel] < (/*edgeLimit*/edgeLimits[whichToIncr] - 1)) { 
      println("current position is below edge limit, increment.");
      offsetArray[currentLevel]++;  //increment offset at current level position
      //nextPath doesn't change, uses current one, just changes offset
    } else {
      println("current position is at edge limit, set it to 0 and decrease which to increment");
      offsetArray[currentLevel] = 0;
      if (whichToIncr > 0) {
        whichToIncr--;
        if (whichToIncr > 0) {
          nextPath = prevPaths[whichToIncr-1];
        } else {
          nextPath = firstPath;
        }
      }

      decrementing = true;
      recurseDown(currentLevel - 1);
    }
  }
}

public Edge getEdgeOf(boolean relTrue, String pathRel, String startOrEnd, String otherObject, int offsetNum, int level) { 
  try { 
    json = loadJSONObject(getPath(otherObject, relTrue, pathRel, startOrEnd, 1, offsetNum));
    //println("searching " + getPath(otherObject, relTrue, pathRel, startOrEnd, 1, offsetNum));
  } 
  catch (NullPointerException e) {
    e.printStackTrace();
    exception = true;
    return null;
  } 

  //  if (json.hasKey("edges")) {
  //    println("has array of edges");
  //  } else {
  //    println("no array of edges!!");
  //  }
  JSONArray jsonEdges = json.getJSONArray("edges");
  JSONObject edge;
  String startLemmas, endLemmas, start, end, rel;
  String finalName = "";
  String finalPath = "";
  boolean omit = false;
  Edge thisEdge;

  if (jsonEdges.size() != 0) {
    //println("has array of edges");


    //for (int i = 0; i < theseEdges.length; i++) {
    edge = jsonEdges.getJSONObject(0);
    startLemmas = edge.getString("startLemmas");
    endLemmas = edge.getString("endLemmas");
    start = edge.getString("start");
    end = edge.getString("end");
    rel = edge.getString("rel"); 

    //get name and path
    if (end.equals(start)) {
      finalName = "REPEAT!";
      finalPath = "REPEAT!";
      omit = true;
    }  
    //this normally is an else if. but i'm getting bugs because i can't exclude the omits right now. so still giving them names and paths.
    /*else*/    if (end.contains(otherObject)) { 
      String splitString[] = split(start, "/");
      finalName = splitString[3];
      finalPath = start;
    } else if (start.contains(otherObject)) {
      String splitString[] = split(end, "/");
      finalName = splitString[3];
      finalPath = end;
    } else {
      finalName = "???";
      finalPath = "???";
    }

    //add an omit condition based on if it matches any path in the search chain?
    for (int i = 0; i < whichToIncr; i++) {
      if (prevPaths[i].equals(finalPath) || finalPath.equals(firstPath)) {
        omit = true;
      }
    }

    if (!finalPath.contains("/c/en/")) {
      omit = true;
    }

    if (finalPath.contains("/v/") || finalPath.contains("/r/") || finalPath.contains("/a")) {
      omit = true;
    }

    if (finalPath.length() > 25) {//37) { //cull large concepts
      omit = true;
    }

    if (finalName.equals("something") || finalName.equals("someone") || finalName.equals("especially")) {
      omit = true;
    }

    thisEdge = new Edge(startLemmas, endLemmas, start, end, rel, finalName, finalPath, level, omit);
    //    println("edge number " + i + ":" + "\n" +
    //        "\t" + "start = " + start + "\n" + 
    //        "\t" + "end = " + end + "\n" + 
    //        "\t" + "finalPath = " + finalPath + "\n" + 
    //        "\t" + "finalName = " + finalName + "\n" + 
    //        "\t" + "relation = " + rel + "\n" + 
    //        "\t" + "level = " + level);
    //}
    return thisEdge;
  } else {
    //println("no array of edges!!");
    return null;
  }
} 

public String getPath(String searchObject, boolean relTrue, String relString, String startOrEnd, int limitNum, int offsetNum) { 
  String newPath = "";
  // relation search, single query
  if (relTrue && offsetNum > 0) {//offsetTrue) {
    newPath = path + "/search?rel=" + relString + "&" + startOrEnd + "=" + searchObject + "&limit=" + limitNum + "&offset=" + offsetNum + "&filter=/c/en";
  } 
  //relation search, normal (limited) query
  if (relTrue && offsetNum == 0) {//!offsetTrue) { 
    newPath = path + "/search?rel=" + relString + "&" + startOrEnd + "=" + searchObject + "&limit=" + limitNum + "&filter=/c/en";
  } 
  // no relation search, normal (limited) query
  if (!relTrue && offsetNum == 0) {//!offsetTrue) {
    newPath = path + searchObject + "?limit=" + limitNum + "&filter=/c/en";
  }
  // no relation search, single query
  if (!relTrue && offsetNum > 0) {//offsetTrue) {
    newPath = path + searchObject + "?limit=" + limitNum + "&offset=" + offsetNum + "&filter=/c/en";
  } 
  //println("calculated path is " + newPath); 
  //println(newPath);
  return newPath;
} 

private void saveStatus() {
  loggedSuccesses = loadStrings("successes.txt");
  String decrementingString;
  if (decrementing == true) {
    decrementingString = "true";
  } else {
    decrementingString = "false";
  }
  String[] statusString = {
    str(edgeLimit), 
    str(levelLimit), 
    firstPath, 
    nextPath, 
    decrementingString, 
    str(whichToIncr), 
    str(offsetArray[0]), str(offsetArray[1]), str(offsetArray[2]), str(offsetArray[3]), str(offsetArray[4]), 
    str(offsetArray[5]), str(offsetArray[6]), str(offsetArray[7]), str(offsetArray[8]), str(offsetArray[9]), 
    str(offsetArray[10]), str(offsetArray[11]), str(offsetArray[12]), 

    prevPaths[0], prevPaths[1], prevPaths[2], prevPaths[3], prevPaths[4], 
    prevPaths[5], prevPaths[6], prevPaths[7], prevPaths[8], prevPaths[9], 
    prevPaths[10], prevPaths[11], prevPaths[12], 

    prevNames[0], prevNames[1], prevNames[2], prevNames[3], prevNames[4], 
    prevNames[5], prevNames[6], prevNames[7], prevNames[8], prevNames[9], 
    prevNames[10], prevNames[11], prevNames[12]
  };
  saveStrings("status.txt", statusString);


  String[] newSuccesses = new String[successNames.size()];
  for (int i = 0; i < successNames.size (); i++) {
    String[] success = successNames.get(i);
    String thisSuccess = "person,";
    for (int j = 0; j < success.length; j++) {
      thisSuccess += success[j] + ",";
    }
    if (!success[success.length-1].equals("money")) {
      thisSuccess += "money";
    }
    newSuccesses[i] = thisSuccess;
  }

  for (int i = 0; i < loggedSuccesses.length; i++) {
    for (int j = 0; j < newSuccesses.length; j++) {
      if (newSuccesses[j].equals(loggedSuccesses[i])) {
        newSuccesses[j] = "OMIT";
      }
    }
  }

  println("from array size " + newSuccesses.length);

  int newArraySize = newSuccesses.length;
  for (int i = 0; i < newSuccesses.length; i++) {
    if (newSuccesses[i].equals("OMIT")) {
      newArraySize--;
    }
  }

  String[] newNewSuccesses = new String[newArraySize];
  int index = 0;
  for (int i = 0; i < newSuccesses.length; i++) {
    if (!newSuccesses[i].equals("OMIT")) {
      newNewSuccesses[index] = newSuccesses[i];
      index++;
    }
  }

  String[] newNewNewSuccesses = concat(loggedSuccesses, newNewSuccesses);

  saveStrings("successes.txt", newNewNewSuccesses);

  successNames.clear();

  //  String[] successNamesArray = new String[successNames.size() + loggedSuccesses.length];
  //  for (int i = 0; i < loggedSuccesses.length; i++) {
  //    successNamesArray[i] = loggedSuccesses[i];
  //  }


  //  for (int i = loggedSuccesses.length; i < loggedSuccesses.length + successNames.size(); i++) {
  //    String[] success = successNames.get(i - loggedSuccesses.length);
  //    String thisSuccess = "person,";
  //    for (int j = 0; j < success.length; j++) {
  //      thisSuccess += success[j] + ",";
  //    }
  //    if (!success[success.length-1].equals("money")) {
  //      thisSuccess += "money";
  //    }
  //    successNamesArray[i] = thisSuccess;
  //  }
  // saveStrings("successes.txt", successNamesArray);
}

