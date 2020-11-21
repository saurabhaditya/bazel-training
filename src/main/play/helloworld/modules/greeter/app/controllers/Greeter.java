package controllers;

import java.util.*;
import play.*;
import play.mvc.*;

public class Greeter extends Controller {
    public static void index(String name) {
        render(name);
    }
}
