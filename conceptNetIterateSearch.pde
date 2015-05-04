// max recursion number for each level
// search one object at a time, increment individual counter
// when reach limit, go one level down further

final int edgeLimit = 5;
final int levelLimit = 10;

final String path = "http://conceptnet5.media.mit.edu/data/5.2";

JSONObject json;

int[] resultsTracker = new int[levelLimit];
String[] resultsTrackerString = new String[levelLimit];
String[] resultsTrackerRelString = new String[levelLimit];  // trying to record relation data to see if it semantically makes sense to me... breaking with a null pointer. 

int offset = -1; 
boolean offsetChanged = false;

void setup() {
  size(400, 400);
  background(250);
  frameRate(30);
}

void draw() {
  if (offsetChanged == true) {
    Edge newEdge = getEdgeOf(false, "", "", "/c/en/person", offset, 1);
    println("start: " + newEdge.start);
    println("end: " + newEdge.end);
    println("startLemmas: " + newEdge.startLemmas);
    println("endLemmas: " + newEdge.endLemmas);
    println("rel: " + newEdge.rel);
    println("FINAL NAME: " + newEdge.finalName);
    println("FINAL PATH: " + newEdge.finalPath);
    println("omit? " + newEdge.omit);
  }
  offsetChanged = false;
}

void keyReleased() {
  offset++;
  offsetChanged = true;
  println("offset = " + offset);
} 


public Edge getEdgeOf(boolean relTrue, String pathRel, String startOrEnd, String otherObject, int offsetNum, int level) { 
  try { 
    json = loadJSONObject(getPath(otherObject, relTrue, pathRel, startOrEnd, 1, offsetNum));
  } 
  catch (NullPointerException e) {
    e.printStackTrace();
    return null;
  } 
  JSONArray jsonEdges = json.getJSONArray("edges");
  JSONObject edge;
  String startLemmas, endLemmas, start, end, rel;
  String finalName = "";
  String finalPath = "";
  boolean omit = false;
  Edge thisEdge;

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
  } else if (end.contains(otherObject)) { 
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

