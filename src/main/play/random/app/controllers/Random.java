package controllers;

import java.util.*;
import org.apache.commons.math3.random.RandomDataGenerator;
import play.*;
import play.mvc.*;

public class Random extends Controller {

    public static void index() {
        String random = new RandomDataGenerator().nextSecureHexString(16);
        render(random);
    }
}
