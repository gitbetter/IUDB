package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.sql.*;
import java.io.*;
import crypt.BCrypt;
import java.util.UUID;

public final class login_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {


	public boolean inputsValid(HttpServletRequest request) {
		String username = request.getParameter("username");
		String password = request.getParameter("password");
		return username != null && password != null 
				&& !username.isEmpty() && !password.isEmpty();
	}

	public void goToHomePage(HttpServletResponse response) {
		try {
			response.sendRedirect(response.encodeRedirectURL("/home.jsp"));
		} catch (IOException ex) { System.out.println(ex); }
	}

	public void newSessionToken(Connection conn, HttpSession session, String username, String password) {
		String sessionId = UUID.randomUUID().toString();
		session.setAttribute("session_token", sessionId);
		try {
			PreparedStatement saveToken = conn.prepareStatement("UPDATE _users SET session_token = ? WHERE username = ? AND password = ?");
			saveToken.setString(1, sessionId);
			saveToken.setString(2, username);
			saveToken.setString(3, password);
			saveToken.execute();
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }
	}

	public String logUserIn(Connection conn, HttpSession session, String username, String password) {
		try {
			PreparedStatement stmt = conn.prepareStatement("SELECT * FROM _users WHERE username = ?");
			stmt.setString(1, username);
			ResultSet result = stmt.executeQuery();

			if (result.next()) {
				String hashedPass = result.getString("password");

				if (BCrypt.checkpw(password, hashedPass)) {
					newSessionToken(conn, session, username, hashedPass);
					return null;
				} 

				return "Incorrect username/password. Please try again.";
			} 

			return "That username does not exist";
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return "";
	}

	public String signUserUp(Connection conn, HttpSession session, String username, String password) {
		try {
			PreparedStatement userFetch = conn.prepareStatement("SELECT * FROM _users WHERE username = ?");
			userFetch.setString(1, username);
			ResultSet result = userFetch.executeQuery();

			if (result.next()) 
					return "That username already exists. Try another or login.";

			String hashedPass = BCrypt.hashpw(password, BCrypt.gensalt(12));
			PreparedStatement stmt = conn.prepareStatement("INSERT INTO _users (username, password) VALUES (?, ?)");
			stmt.setString(1, username);
			stmt.setString(2, hashedPass);

			if(!stmt.execute()) 
					return "There was an error creating your account. Please try again later.";

			newSessionToken(conn, session, username, password);
			return null;
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return "";
	}

	public boolean isLoggedIn(Connection conn, HttpSession session) {
		Object token = session.getAttribute("session_token");
		if (token == null) return false;

		String tokenString = token.toString();

		try {
			PreparedStatement query = conn.prepareStatement("SELECT COUNT(*) AS usersWithToken FROM _users WHERE session_token = ?");
			query.setString(1, tokenString);
			ResultSet results = query.executeQuery();
			results.next();
			return results.getInt("usersWithToken") > 0;
		} catch(SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return false;
	}

  private static java.util.Vector _jspx_dependants;

  public java.util.List getDependants() {
    return _jspx_dependants;
  }

  public void _jspService(HttpServletRequest request, HttpServletResponse response)
        throws java.io.IOException, ServletException {

    JspFactory _jspxFactory = null;
    PageContext pageContext = null;
    HttpSession session = null;
    ServletContext application = null;
    ServletConfig config = null;
    JspWriter out = null;
    Object page = this;
    JspWriter _jspx_out = null;
    PageContext _jspx_page_context = null;


    try {
      _jspxFactory = JspFactory.getDefaultFactory();
      response.setContentType("text/html");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;

      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write('\n');

	String connectionString = "jdbc:postgresql://class-db.cs.fiu.edu:5432/spr18_asanc412?user=spr18_asanc412&password=6055117";	
	Class.forName("org.postgresql.Driver").newInstance();
	Connection connection = DriverManager.getConnection(connectionString);

	String attemptedLogin = request.getParameter("login_button");
	String attemptedSignup = request.getParameter("signup_button");
	String username = request.getParameter("username");
	String password = request.getParameter("password");

	String errorText = null;

	if(isLoggedIn(connection, session)) 
		goToHomePage(response);

	if(attemptedLogin != null) {
		if (inputsValid(request)) {
			errorText = logUserIn(connection, session, username, password);
			if (errorText == null)
				goToHomePage(response);
		} else {
			errorText = "A valid username and password are required to login";
		}
	} 
	else if (attemptedSignup != null) {
		if (inputsValid(request)) {
			errorText = signUserUp(connection, session, username, password);
			if (errorText == null)
				goToHomePage(response);
		} else {
			errorText = "A valid username and password are required to sign up";
		}
	}

      out.write("\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("<head>\n");
      out.write("\t<title>IUDB - Internet University Database</title>\n");
      out.write("\t<meta charset=\"UTF-8\">\n");
      out.write("\t<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css\" integrity=\"sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm\" crossorigin=\"anonymous\">\n");
      out.write("\t<link href=\"https://fonts.googleapis.com/css?family=Abril+Fatface\" rel=\"stylesheet\">\n");
      out.write("\t<style type=\"text/css\">\n");
      out.write("\t\thtml {\n");
      out.write("\t\t\tbackground-image: url('images/books.jpg');\n");
      out.write("\t\t\tbackground-size: cover;\n");
      out.write("\t\t\tbackground-repeat: no-repeat;\n");
      out.write("\t\t\tbackground-position: 0 0;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\thtml, body {\n");
      out.write("\t\t\twidth: 100%; height: 100%;\n");
      out.write("\t\t\toverflow: hidden;\n");
      out.write("\t\t\tbackground-color: transparent;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.divider-text {\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tfont-size: 12pt;\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t\tfont-weight: 200;\n");
      out.write("\t\t\tcolor: rgba(0, 0, 0, 0.57);\n");
      out.write("\t\t\tdisplay: inline-block;\n");
      out.write("\t\t\tmargin: 0 20px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.error-label {\n");
      out.write("\t\t\tcolor: #5E322D;\n");
      out.write("\t\t\tfont-size: 10pt;\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t\tposition: absolute;\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t\tbottom: 10px;\n");
      out.write("\t\t\tleft: 0;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#form-container {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\tbackground: #CABCAA;\n");
      out.write("\t\t\twidth: 25%;\n");
      out.write("\t\t\theight: auto;\n");
      out.write("\t\t\tfloat: left;\n");
      out.write("\t\t\tleft: 30px;\n");
      out.write("\t\t\ttop: 30px;\n");
      out.write("\t\t\tborder-radius: 5px;\n");
      out.write("\t\t\tborder: 4px solid #5E322D;\n");
      out.write("\t\t\tpadding: 20px;\n");
      out.write("\t\t\toverflow: hidden;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#form-container > h3 {\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t\tfont-size: 14pt;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#login-form {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\twidth: 100%; height: auto;\t\t\t\n");
      out.write("\t\t}\t\t\n");
      out.write("\n");
      out.write("\t\t#login-form > input[type=\"text\"],\n");
      out.write("\t\t#login-form > input[type=\"password\"] {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\twidth: 75%; height: 30px;\n");
      out.write("\t\t\tbackground-color: rgba(255, 255, 255, 0.4);\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t\tborder-radius: 5px;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t\tfont-size: 16pt;\n");
      out.write("\t\t\tdisplay: block;\n");
      out.write("\t\t\tmargin: 0 auto;\n");
      out.write("\t\t\tmargin-top: 25px;\n");
      out.write("\t\t\tmargin-bottom: 15px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#login-form-buttons > input[type=\"submit\"] {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\twidth: 30%; height: 100%;\n");
      out.write("\t\t\tbackground-color: rgba(255, 255, 255, 0.4);\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t\tborder: 1px solid #5E322D;\n");
      out.write("\t\t\tborder-radius: 3px;\n");
      out.write("\t\t\tfont-size: 12pt;\n");
      out.write("\t\t\tfont-family: \"Helvetica\"\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#login-form-buttons {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tmargin: 35px;\n");
      out.write("\t\t\theight: 30px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#site-header {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tpadding: 20px;\n");
      out.write("\t\t\tfont-family: \"Abril Fatface\", cursive;\n");
      out.write("\t\t\tfont-size: 28pt;\n");
      out.write("\t\t}\n");
      out.write("\t</style>\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body>\n");
      out.write("\t<div id=\"form-container\">\n");
      out.write("\t\t<h2 id=\"site-header\">IUDB</h2>\n");
      out.write("\t\t<h3 style=\"color: rgba(0, 0, 0, 0.6);\">Log in or create an account to access the internet university database.</h3>\n");
      out.write("\t\t<form id=\"login-form\" method=\"POST\" action=\"login.jsp\">\n");
      out.write("\t\t\t<input type=\"text\" name=\"username\" placeholder=\"Username\">\n");
      out.write("\t\t\t<input type=\"password\" name=\"password\" placeholder=\"Password\">\n");
      out.write("\t\t\t<div id=\"login-form-buttons\">\n");
      out.write("\t\t\t\t<input type=\"submit\" name=\"login_button\" value=\"Log In\">\n");
      out.write("\t\t\t\t<p class=\"divider-text\">OR</p>\t\t\t\n");
      out.write("\t\t\t\t<input type=\"submit\" name=\"signup_button\" value=\"Sign Up\">\n");
      out.write("\t\t\t</div>\n");
      out.write("\t\t</form>\n");
      out.write("\t\t");
 if(errorText != null) { 
      out.write("\n");
      out.write("\t\t<p class=\"error-label\">");
      out.print( errorText );
      out.write("</p>\n");
      out.write("\t\t");
 } 
      out.write("\n");
      out.write("\t</div>\n");
      out.write("</body>\n");
      out.write("</html>\n");
    } catch (Throwable t) {
      if (!(t instanceof SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          out.clearBuffer();
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
      }
    } finally {
      if (_jspxFactory != null) _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}
