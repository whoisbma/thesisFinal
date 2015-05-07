// max recursion number for each level
// search one object at a time, increment individual counter
// when reach limit, go one level down further

//several potential problems:
//1 - my logic on null and omit skips has an issue, especially if its in the "currentLevel" slot and not just skipping on its way towards it. probably a problem, yes.
//2 - it does an extra path search more than necessary during a normal "pull back".
//3 - in the last stage it resets all to zero while pulling back, apparently. not necessary to happen.



final int edgeLimit = 5;
final int levelLimit = 5;

final String path = "http://conceptnet5.media.mit.edu/data/5.2";

JSONObject json;

//int[] resultsTracker = new int[levelLimit];
//String[] resultsTrackerString = new String[levelLimit];
//String[] resultsTrackerRelString = new String[levelLimit];  // trying to record relation data to see if it semantically makes sense to me... breaking with a null pointer. 

//int offset = 0; 
int[] offsetArray = new int[levelLimit];
char[] offsetChar = new char[levelLimit]; //just to test
int whichToIncr = 0; // for testing above
boolean decrementing = false; 

int totalPaths = 0;
int totalRecurses = 0;
int totalOmits = 0;
int totalNulls = 0;

String firstPath = "/c/en/person";
String nextPath = firstPath;

String[] prevPaths = new String[levelLimit]; 

boolean done = false;

void setup() {
  size(400, 400);
  background(250);
  frameRate(2);

  for (int i = 0; i < levelLimit; i++) {
    offsetArray[i] = 0;
    offsetChar[i] = 'O';
    prevPaths[i] = "";
  }
}

void draw() {
  if (done == false) {
    recurseDown(levelLimit-1);
  }
}

public void recurseDown(int currentLevel) {
  totalRecurses++;
  if (currentLevel < 0) {
    println("done");
    println("total paths: " + totalPaths);
    println("total recurses: " + totalRecurses);
    println("total omits: " + totalOmits);
    println("total nulls: " + totalNulls);
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

  print("search chain: " + firstPath + " --> ");
  for (int i = 0; i < whichToIncr; i++) {
    print(prevPaths[i] + " - ");
  }
  println();

  //----------------------------------------------------------------------
  //searching next path---------------------------------------------------
  //----------------------------------------------------------------------
  print("searching: " + nextPath + ", ");
  Edge newEdge = getEdgeOf(false, "", "", nextPath, offsetArray[whichToIncr], 1);

  //----------------------------------------------------------------------
  //if new edge is null,--------------------------------------------------
  //----------------------------------------------------------------------
  if (newEdge == null) {
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

    if (whichToIncr == levelLimit) {
      println("whichToIncr == levelLimit, recursing and decrementing");
      decrementing = true;
      recurseDown(currentLevel);
    } else {
      decrementing = true;
      recurseDown(whichToIncr);
    }

    //----------------------------------------------------------------------
    //if new edge is to be omitted,-----------------------------------------
    //----------------------------------------------------------------------
  } else if (newEdge.omit == true) {    //should it be omitted?
    totalOmits++;
    print("found: " + newEdge.finalPath + " - OMIT - ");

    if (offsetArray[whichToIncr] < (edgeLimit - 1)) { 
      println("current position is below edge limit, increment.");
      println();
      offsetArray[whichToIncr]++;  //increment offset at current level position
      //nextPath doesn't change, uses current one, just changes offset
    } else {
      println("current position is at edge limit, set it to 0 and decrease which to increment");
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
      if (whichToIncr == levelLimit) {
        println("whichToIncr == levelLimit, recursing and decrementing");
        decrementing = true;
        recurseDown(currentLevel);
      } else {
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
    totalPaths++;

    print("current chain: " + firstPath + " --> ");
    for (int i = 0; i < whichToIncr; i++) {
      print(prevPaths[i] + " - ");
    }
    print(newEdge.finalPath);
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

    if (offsetArray[currentLevel] < (edgeLimit - 1)) { 
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

