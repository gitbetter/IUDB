package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.io.*;
import java.util.Enumeration;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.sql.*;

public final class home_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {


	DateFormat dateDisplayF = new SimpleDateFormat("MM-dd-yyyy");
	DateFormat jdbcDateF = new SimpleDateFormat("yyyy-MM-dd");

	public boolean isStringSet(String s) {
		return s != null && !s.isEmpty();
	}

	public String dateFormatJDBC(String dateString) {
		System.out.println(dateString);
		try {
			java.util.Date date = dateDisplayF.parse(dateString);
			return jdbcDateF.format(date);
		} catch (ParseException ex) { System.out.println(ex); }

		return null;
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

	public void goToLoginPage(HttpServletResponse response) {
		try {
			response.sendRedirect(response.encodeRedirectURL("/login.jsp"));
		} catch (IOException ex) { System.out.println(ex); }
	}

	public boolean hasValidSearch(HttpServletRequest request) {
		String searchFilter = request.getParameter("queryOptions");
		String searchQuery = request.getParameter("searchQuery");
		
		return isStringSet(searchFilter) && isStringSet(searchQuery);
	}

	public boolean hasQueryOption(HttpServletRequest request) {
		String qOption = request.getParameter("queryOptions");
		return isStringSet(qOption);
	}

	public boolean isUpdate(HttpServletRequest request) {
		String qOption = request.getParameter("updateType");
		return isStringSet(qOption);
	}

	public boolean isDelete(HttpServletRequest request) {
		String qOption = request.getParameter("deleteType");
		return isStringSet(qOption);
	}

	public ResultSet fetchInstructorNames(Connection conn) {
		PreparedStatement stmt = null;
		ResultSet results = null;
		try {
			stmt = conn.prepareStatement("SELECT faculty_id, name FROM vFaculty", 
											ResultSet.TYPE_SCROLL_SENSITIVE, 
			                        		ResultSet.CONCUR_UPDATABLE);
			results = stmt.executeQuery();
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return results;
	}

	public ResultSet fetchAllStudents(Connection conn) {
		PreparedStatement stmt = null;
		ResultSet results = null;
		try {
			stmt = conn.prepareStatement("SELECT student_id, name, email FROM vStudents", 
											ResultSet.TYPE_SCROLL_SENSITIVE, 
			                        		ResultSet.CONCUR_UPDATABLE);
			results = stmt.executeQuery();
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return results;
	}

	public ResultSet fetchAllCourses(Connection conn) {
		PreparedStatement stmt = null;
		ResultSet results = null;
		try {
			stmt = conn.prepareStatement("SELECT course_id, description, level, semester, instructor FROM vCourses", 
											ResultSet.TYPE_SCROLL_SENSITIVE, 
			                        		ResultSet.CONCUR_UPDATABLE);
			results = stmt.executeQuery();
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return results;
	}

	public ResultSet fetchQueryResults(Connection conn, String type, String queryString) {
		PreparedStatement stmt = null;
		ResultSet results = null;
		try {
			if (type.equals("Students")) {
				stmt = isStringSet(queryString) ? conn.prepareStatement("SELECT * FROM vStudents WHERE name ~* ?") :
											 conn.prepareStatement("SELECT * FROM vStudents"); 
				if (isStringSet(queryString)) stmt.setString(1, ".*" + queryString + ".*");
			} else if (type.equals("Faculty")) {
				stmt = isStringSet(queryString) ? conn.prepareStatement("SELECT * FROM vFaculty WHERE name ~* ?") :
											 conn.prepareStatement("SELECT * FROM vFaculty");
				if (isStringSet(queryString)) stmt.setString(1, ".*" + queryString + ".*");
			} else if (type.equals("Courses")) {
				stmt = isStringSet(queryString) ? conn.prepareStatement("SELECT * FROM vCourses WHERE description ~* ?") :
											 conn.prepareStatement("SELECT * FROM vCourses");
				if (isStringSet(queryString)) stmt.setString(1, ".*" + queryString + ".*");

				// Additionally fetch instructor options for courses
				instructorNames = fetchInstructorNames(conn);
			} else if (type.equals("Enrollments")) {
				stmt = conn.prepareStatement("SELECT * FROM vStudentEnrollments");

				// Additionally fetch student and course options for enrollments
				allStudents = fetchAllStudents(conn);
				allCourses = fetchAllCourses(conn);
			}

			if (stmt != null) {
				results = stmt.executeQuery();
			}
		} catch (SQLException ex) { System.out.println("SQL Exception: " + ex); }

		return results; 
	}

	public ResultSet fetchQueryResults(Connection conn, String type) {
		return fetchQueryResults(conn, type, null);
	}

	public boolean performUpdate(Connection conn, String updateType, String pk[], String vals[]) {
		PreparedStatement stmt = null;
		try {
			if (updateType.equals("Students")) {
				stmt = conn.prepareStatement("UPDATE students SET name = ?, email = ?, date_of_birth = ?, address = ?, level = ? WHERE student_id = ?"); 
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setDate(3, Date.valueOf(dateFormatJDBC(vals[2])));
				stmt.setString(4, vals[3]);
				stmt.setString(5, vals[4]);
				stmt.setInt(6, Integer.parseInt(pk[0]));
			} else if (updateType.equals("Faculty")) {
				stmt = conn.prepareStatement("UPDATE faculty SET name = ?, email = ?, date_of_birth = ?, address = ?, level = ? WHERE faculty_id = ?"); 
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setDate(3, Date.valueOf(dateFormatJDBC(vals[2])));
				stmt.setString(4, vals[3]);
				stmt.setString(5, vals[4]);
				stmt.setInt(6, Integer.parseInt(pk[0]));
			} else if (updateType.equals("Courses")) {
				stmt = conn.prepareStatement("UPDATE courses SET description = ?, level = ?, semester = ?, instructor = ? WHERE course_id = ?");
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setString(3, vals[2]);
				stmt.setInt(4, Integer.parseInt(vals[3]));
				stmt.setInt(5, Integer.parseInt(pk[0]));
			} else if (updateType.equals("Enrollments")) {
				stmt = conn.prepareStatement("UPDATE enroll SET grade = ? WHERE student_id = ? AND course_id = ?");
				stmt.setString(1, vals[0]);
				stmt.setInt(2, Integer.parseInt(pk[0]));
				stmt.setInt(3, Integer.parseInt(pk[1]));
			}

			if (stmt != null)
				stmt.execute();
			return true;
		} catch (SQLException ex) { System.out.println(ex); }

		return false;
	}

	public boolean performInsert(Connection conn, String updateType, String vals[]) {
		PreparedStatement stmt = null;
		try {
			if (updateType.equals("Students")) {
				stmt = conn.prepareStatement("INSERT INTO students (name, email, date_of_birth, address, level) VALUES (?, ?, ?, ?, ?)"); 
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setDate(3, Date.valueOf(dateFormatJDBC(vals[2])));
				stmt.setString(4, vals[3]);
				stmt.setString(5, vals[4]);
			} else if (updateType.equals("Faculty")) {
				stmt = conn.prepareStatement("INSERT INTO students (name, email, date_of_birth, address, level) VALUES (?, ?, ?, ?, ?)"); 
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setDate(3, Date.valueOf(dateFormatJDBC(vals[2])));
				stmt.setString(4, vals[3]);
				stmt.setString(5, vals[4]);
			} else if (updateType.equals("Courses")) {
				stmt = conn.prepareStatement("INSERT INTO courses (description, level, semester, instructor) WHERE VALUES (?, ?, ?, ?)");
				stmt.setString(1, vals[0]);
				stmt.setString(2, vals[1]);
				stmt.setString(3, vals[2]);
				stmt.setInt(4, Integer.parseInt(vals[3]));
			} else if (updateType.equals("Enrollments")) {
				stmt = conn.prepareStatement("INSERT INTO enroll (student_id, course_id, grade) VALUES(?, ?, ?)");
				stmt.setInt(1, Integer.parseInt(vals[0]));
				stmt.setInt(2, Integer.parseInt(vals[1]));
				stmt.setString(3, vals[2]);
			}

			if (stmt != null)
				stmt.execute();
			return true;
		} catch (SQLException ex) { System.out.println(ex); }

		return false;
	}

	public boolean performDelete(Connection conn, String deleteType, String pk[]) {
		PreparedStatement stmt = null;
		try {
			if (deleteType.equals("Students")) {
				stmt = conn.prepareStatement("DELETE FROM students WHERE student_id = ?"); 
				stmt.setInt(1, Integer.parseInt(pk[0]));
			} else if (deleteType.equals("Faculty")) {
				stmt = conn.prepareStatement("DELETE FROM faculties WHERE faculty_id = ?"); 
				stmt.setInt(1, Integer.parseInt(pk[0]));
			} else if (deleteType.equals("Courses")) {
				stmt = conn.prepareStatement("DELETE FROM courses WHERE course_id = ?"); 
				stmt.setInt(1, Integer.parseInt(pk[0]));
			} else if (deleteType.equals("Enrollments")) {
				stmt = conn.prepareStatement("DELETE FROM enroll WHERE student_id = ? AND course_id = ?");
				stmt.setInt(1, Integer.parseInt(pk[0]));
				stmt.setInt(2, Integer.parseInt(pk[1]));
			}

			if (stmt != null)
				stmt.execute();
			return true;
		} catch (SQLException ex) { System.out.println(ex); }

		return false;
	}

	boolean hasResults;
	boolean successfulUpdate;
	ResultSet qResults, instructorNames, allCourses, allStudents;
	String queryOption;

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

	if (!isLoggedIn(connection, session)) 
		goToLoginPage(response);

	queryOption = null;
	qResults = null;
	hasResults = false;
	successfulUpdate = false;

	if(hasValidSearch(request)) {
		queryOption = request.getParameter("queryOptions");
		String searchQuery = request.getParameter("searchQuery");
		qResults = fetchQueryResults(connection, queryOption, searchQuery);		
	} else if(hasQueryOption(request) && request.getParameter("wasSearch").equals("false")) {
		queryOption = request.getParameter("queryOptions");
		qResults = fetchQueryResults(connection, queryOption);
	} else if(isUpdate(request)) {
		queryOption = request.getParameter("updateType");
		Enumeration paramNames = request.getParameterNames();
		while (paramNames.hasMoreElements()) {
			String param = (String) paramNames.nextElement();
			if (param.equals("updateType")) continue;

			String csvArgs = request.getParameter(param);
			String vals[] = csvArgs.split(",");
			if (param.contains("newEntry")) {
				successfulUpdate = performInsert(connection, queryOption, vals);	
			} else {
				String params[] = param.split(",");
				successfulUpdate = performUpdate(connection, queryOption, params, vals);
			}
		}

		qResults = fetchQueryResults(connection, queryOption);
	} else if(isDelete(request)) {
		queryOption = request.getParameter("deleteType");
		String primaryKey = request.getParameter("primaryKey");
		String pk[] = primaryKey.split(",");

		successfulUpdate = performDelete(connection, queryOption, pk);
		qResults = fetchQueryResults(connection, queryOption);
	}

      out.write("\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("<head>\n");
      out.write("\t<title>IUDB - HOME</title>\n");
      out.write("\t<meta charset=\"UTF-8\">\n");
      out.write("\t<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css\" integrity=\"sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm\" crossorigin=\"anonymous\">\n");
      out.write("\t<link href=\"https://fonts.googleapis.com/css?family=Abril+Fatface\" rel=\"stylesheet\">\n");
      out.write("\t<script defer src=\"https://use.fontawesome.com/releases/v5.0.9/js/all.js\" integrity=\"sha384-8iPTk2s/jMVj81dnzb/iFR2sdA7u06vHJyyLlAd4snFpCl/SnyUjRrbdJsw1pGIl\" crossorigin=\"anonymous\"></script>\n");
      out.write("\t<style type=\"text/css\">\n");
      out.write("\t\thtml, body {\n");
      out.write("\t\t\twidth: 100%; height: 100%;\n");
      out.write("\t\t\toverflow: hidden;\n");
      out.write("\t\t\tbackground-color: transparent;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tinput[type=\"text\"], *:focus {\n");
      out.write("\t\t\tbox-shadow: none !important;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\ta { \n");
      out.write("\t\t\ttext-decoration: none !important;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.content-container {\n");
      out.write("\t\t\theight: 100%;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.no-results-cta {\n");
      out.write("\t\t\tmargin-bottom: 0;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#nav-menu {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#nav-menu > a {\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#nav-menu-container {\n");
      out.write("\t\t\theight: 100%;\n");
      out.write("\t\t\tpadding: 0;\n");
      out.write("\t\t\tborder-right: 1px solid lightgray;\n");
      out.write("\t\t}\t\n");
      out.write("\n");
      out.write("\t\t#site-header {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tpadding: 20px;\n");
      out.write("\t\t\tfont-family: \"Abril Fatface\", cursive;\n");
      out.write("\t\t\tfont-size: 26pt;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#logout-button {\n");
      out.write("\t\t\tbackground-color: #f8f9fa;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#user-menu {\n");
      out.write("\t\t\tposition: absolute;\n");
      out.write("\t\t\tbottom: 0;\n");
      out.write("\t\t\tleft: 0;\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#user-menu > a {\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#query-form {\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#query-form > .input-group {\n");
      out.write("\t\t\tmargin: 0;\n");
      out.write("\t\t\tborder-bottom: 1px solid lightgray;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#search-filter {\n");
      out.write("\t\t\tdisplay: inline-block;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#search-filter > .dropdown-toggle {\n");
      out.write("\t\t\tbackground-color: #f8f8f8;\n");
      out.write("\t\t\tcolor: gray;\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t\theight: 100%;\n");
      out.write("\t\t\tmargin-right: 1px;\n");
      out.write("\t\t\tborder-right: 1px solid lightgray;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#search-filter .dropdown-menu {\n");
      out.write("\t\t\tpadding: 0;\n");
      out.write("\t\t\tmargin-top: 1px;\n");
      out.write("\t\t\tborder-radius: 0;\n");
      out.write("\t\t\tborder-left: 0;\n");
      out.write("\t\t\tborder-top: 0;\n");
      out.write("\t\t\tbox-shadow: 0px 0px 5px lightgray;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#search-filter .dropdown-menu > .dropdown-item {\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#search-field {\n");
      out.write("\t\t\tborder: none;\t\n");
      out.write("\t\t\tfont-size: 18pt;\n");
      out.write("\t\t\tpadding: 10px 10px 10px 30px;\n");
      out.write("\t\t\tfont-family: \"Helvetica\";\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#main-container {\n");
      out.write("\t\t\twidth: 100%; max-height: 70%;\n");
      out.write("\t\t\toverflow-y: scroll;\n");
      out.write("\t\t\tborder-top: 1px solid lightgray;\n");
      out.write("\t\t\tborder-bottom: 1px solid lightgray;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.welcome-cta, .no-results-cta {\n");
      out.write("\t\t\tposition: relative;\n");
      out.write("\t\t\ttop: 14%;\n");
      out.write("\t\t\twidth: 75%;\n");
      out.write("\t\t\tmargin: 0 auto;\n");
      out.write("\t\t\tbackground-color: #f8f8f8;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.welcome-cta > h1,\n");
      out.write("\t\t.no-results-cta > h1 {\n");
      out.write("\t\t\tcolor: #000000b3;\n");
      out.write("\t\t\tfont-family: 'Abril Fatface', cursive;\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table {\n");
      out.write("\t\t\twidth: 100%;\n");
      out.write("\t\t\tmargin: 0 auto;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table > thead th,\n");
      out.write("\t\t#info-table > tbody td {\n");
      out.write("\t\t\tpadding: 20px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table > thead th {\n");
      out.write("\t    \tfont-weight: 400;\n");
      out.write("\t\t    font-family: Helvetica;\n");
      out.write("\t\t\tborder-top: none;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table > tbody td {\n");
      out.write("\t\t    font-family: Helvetica;\n");
      out.write("\t\t\tpadding: 10px;\n");
      out.write("\t\t\tvertical-align: middle;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table > tbody td > input {\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t\tbackground-color: #b9b9b933;\n");
      out.write("\t\t\tpadding: 10px;\n");
      out.write("\t\t\ttext-overflow: ellipsis;\n");
      out.write("\t\t\toverflow: hidden;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#info-table > tbody td > input:disabled {\n");
      out.write("\t\t\tbackground-color: transparent;\n");
      out.write("\t\t\tcolor: black;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#data-options {\n");
      out.write("\t\t\ttext-align: center;\n");
      out.write("\t\t\tpadding: 20px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#data-options > button {\n");
      out.write("\t\t\twidth: 46%;\n");
      out.write("\t\t\theight: 60px;\n");
      out.write("\t\t\tborder-radius: 0;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#home-link {\n");
      out.write("\t\t\tcolor: black;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.edit-button, .remove-button {\n");
      out.write("\t\t\tpadding: 10px;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.new-changes-button,\n");
      out.write("\t\t.new-row-button {\n");
      out.write("\t\t\ttransition: all 200ms;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.new-changes-button.disabled {\n");
      out.write("\t\t\tbackground-color: lightgray;\n");
      out.write("\t\t\tborder: lightgray;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tinput.invalid-field {\n");
      out.write("\t\t\tborder: 2px solid #ed9d9d !important;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t#success-box {\n");
      out.write("\t\t\tposition: absolute;\n");
      out.write("\t\t\tleft: 50%;\n");
      out.write("\t\t\ttop: 40%;\n");
      out.write("\t\t\ttransform: translateY(-50%) translateX(-50%);\n");
      out.write("\t\t\tz-index: 500;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.options-field,\n");
      out.write("\t\t.options-field:disabled {\n");
      out.write("\t\t\tborder: none;\n");
      out.write("\t\t\tbackground-color: transparent;\n");
      out.write("\t\t\tcolor: black;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.options-field:disabled {\n");
      out.write("\t\t\tbackground: none;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t/* Success checkmark styles. Fetched from\n");
      out.write("\t\t * https://jsfiddle.net/Hybrid8287/gtb1avet/1/\n");
      out.write("\t\t * Thanks to Michael Draemel!\n");
      out.write("\t\t */\n");
      out.write("\n");
      out.write("\t\t.checkmark__circle {\n");
      out.write("\t  \t\tstroke-dasharray: 166;\n");
      out.write("    \t\tstroke-dashoffset: 166;\n");
      out.write("\t  \t\tstroke-width: 2;\n");
      out.write("\t    \tstroke-miterlimit: 10;\n");
      out.write("\t\t  \tstroke: #7ac142;\n");
      out.write("\t\t    fill: none;\n");
      out.write("\t\t\tanimation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t    .checkmark {\n");
      out.write("\t\t    width: 150px;\n");
      out.write("\t\t    height: 150px;\n");
      out.write("\t\t    border-radius: 50%;\n");
      out.write("\t\t    display: block;\n");
      out.write("\t\t    stroke-width: 2;\n");
      out.write("\t\t    stroke: #fff;\n");
      out.write("\t        stroke-miterlimit: 10;\n");
      out.write("\t\t\tmargin: 10% auto;\n");
      out.write("\t\t    box-shadow: inset 0px 0px 0px #7ac142;\n");
      out.write("\t\t    animation: fill .4s ease-in-out .4s forwards, scale .3s ease-in-out .9s both;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t.checkmark__check {\n");
      out.write("\t\t\ttransform-origin: 50% 50%;\n");
      out.write("\t\t    stroke-dasharray: 48;\n");
      out.write("\t\t    stroke-dashoffset: 48;\n");
      out.write("\t\t    animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;\n");
      out.write("\t    }\n");
      out.write("\n");
      out.write("\t\t@keyframes stroke {\n");
      out.write("\t\t    100% {\n");
      out.write("\t\t\t    stroke-dashoffset: 0;\n");
      out.write("\t\t\t}\n");
      out.write("\t    }\n");
      out.write("\t\t@keyframes scale {\n");
      out.write("\t\t    0%, 100% {\n");
      out.write("\t\t\t    transform: none;\n");
      out.write("\t\t    }\n");
      out.write("\t\t    50% {\n");
      out.write("\t\t\t    transform: scale3d(1.1, 1.1, 1);\n");
      out.write("\t     \t}\n");
      out.write("\t    }\n");
      out.write("\t    @keyframes fill {\n");
      out.write("\t\t    100% {\n");
      out.write("\t\t\t    box-shadow: inset 0px 0px 0px 90px #7ac142;\n");
      out.write("\t\t \t}\n");
      out.write("\t    }\n");
      out.write("\t</style>\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body>\n");
      out.write("\n");
      out.write("\t");
 if (successfulUpdate) { 
      out.write("\n");
      out.write("\t<div id=\"success-box\">\n");
      out.write("\t\t<svg class=\"checkmark\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 52 52\"><circle class=\"checkmark__circle\" cx=\"26\" cy=\"26\" r=\"25\" fill=\"none\"/><path class=\"checkmark__check\" fill=\"none\" d=\"M14.1 27.2l7.1 7.2 16.7-16.8\"/></svg>\n");
      out.write("\t</div>\n");
      out.write("\t");
 } 
      out.write("\n");
      out.write("\n");
      out.write("\t<div class=\"content-container row\">\n");
      out.write("\t\t<div id=\"nav-menu-container\" class=\"col-md-2\">\n");
      out.write("\t\t\t<a id=\"home-link\" href=\"#\"><h3 id=\"site-header\">IUDB</h3></a>\n");
      out.write("\t\t\t<div id=\"nav-menu\" class=\"list-group\">\n");
      out.write("\t\t  \t\t<a href=\"#\" class=\"list-group-item list-group-item-action\">Students</a>\n");
      out.write("\t\t  \t\t<a href=\"#\" class=\"list-group-item list-group-item-action\">Courses</a>\n");
      out.write("\t\t    \t<a href=\"#\" class=\"list-group-item list-group-item-action\">Faculty</a>\n");
      out.write("\t\t\t  \t<a href=\"#\" class=\"list-group-item list-group-item-action\">Enrollments</a>\n");
      out.write("\t\t\t</div>\n");
      out.write("\n");
      out.write("\t\t\t<div id=\"user-menu\">\n");
      out.write("\t\t\t\t<a id=\"logout-button\" href=\"#\" class=\"list-group-item list-group-item-action\">Log out</a>\n");
      out.write("\t\t\t</div>\n");
      out.write("\t\t</div>\n");
      out.write("\t\t<div class=\"col-md-10\" style=\"padding: 0; height: 100%\">\n");
      out.write("\t\t\t<form id=\"query-form\" method=\"POST\" action=\"home.jsp\">\n");
      out.write("\t\t\t\t<div class=\"input-group mb-3\" style=\"margin: 0\">\n");
      out.write("\t\t\t  \t\t<div id=\"search-filter\" class=\"input-group-prepend\">\n");
      out.write("\t\t\t      \t\t<button class=\"btn btn-outline-secondary dropdown-toggle\" type=\"button\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">");
      out.print( isStringSet(queryOption) ? queryOption : "Students" );
      out.write("</button>\n");
      out.write("\t\t\t\t      \t\t<div class=\"dropdown-menu\">\n");
      out.write("\t\t\t\t\t    \t   \t<a class=\"dropdown-item\" href=\"#\">Students</a>\n");
      out.write("\t\t\t\t\t\t\t    <a class=\"dropdown-item\" href=\"#\">Courses</a>\n");
      out.write("\t\t\t\t\t\t\t    <a class=\"dropdown-item\" href=\"#\">Faculty</a>\n");
      out.write("\t\t\t\t\t\t \t</div>\n");
      out.write("\t\t\t\t\t</div>\n");
      out.write("\t\t\t\t    <input id=\"search-field\" type=\"text\" name=\"searchQuery\" class=\"form-control\" aria-label=\"Text input with dropdown button\" placeholder=\"Search\">\n");
      out.write("\t\t\t\t</div>\n");
      out.write("\n");
      out.write("\t\t\t\t<!--Hidden form elements used as a data model-->\n");
      out.write("\t\t\t\t<input type=\"radio\" name=\"queryOptions\" value=\"Students\" hidden>\n");
      out.write("\t\t\t\t<input type=\"radio\" name=\"queryOptions\" value=\"Faculty\" hidden>\n");
      out.write("\t\t\t\t<input type=\"radio\" name=\"queryOptions\" value=\"Courses\" hidden>\n");
      out.write("\t\t\t\t<input type=\"radio\" name=\"queryOptions\" value=\"Enrollments\" hidden>\n");
      out.write("\t\t\t\t<input type=\"hidden\" name=\"wasSearch\" value=\"false\">\n");
      out.write("\t\t\t</form>\n");
      out.write("\n");
      out.write("\t\t\t\t");
 if (qResults == null) { 
      out.write("\n");
      out.write("\t\t\t\t");
 hasResults = false; 
      out.write("\n");
      out.write("\t\t\t\t\n");
      out.write("\t\t\t\t<div class=\"jumbotron welcome-cta\">\n");
      out.write("\t  \t\t\t\t<h1 class=\"display-4\">Internet University DataBase</h1>\n");
      out.write("\t    \t\t\t<p class=\"lead\" style=\"line-height: 45px;\">\n");
      out.write("\t\t\t\t\t\tEasily find what you're looking for by using the search bar and filter at the top, or click on one of the links to the left to display categorical results.\n");
      out.write("\t\t\t\t\t\tAdd some entries by navigating to one of the categories, clicking on the <button type=\"button\" class=\"btn btn-light btn-lg\">Add a New Row</button> button\n");
      out.write("\t\t\t\t\t\tfilling out the new row and hitting enter. \n");
      out.write("\t\t\t\t\t\tClick on the  <i class=\"fas fa-pencil-alt\" style=\"color: #b3b35f; height: 1em;\"></i> icon of an entry to edit that row. \n");
      out.write("\t\t\t\t\t\tWhen you're ready to commit you're changes, click on the <button type=\"button\" class=\"btn btn-primary btn-lg\">Commit Changes</button> button to save\n");
      out.write("\t\t\t\t\t\tyour data to the <span style=\"font-family: 'Abril fatface', cursive\">IUDB</span> database.\n");
      out.write("\t\t\t\t\t\tClick on the  <i class=\"fas fa-minus-circle\" style=\"color: #e04b4b; height: 1em;\"></i>  icon to remove a row. Fields with validation errors will be outlined\n");
      out.write("\t\t\t\t\t\tin <span style=\"color: #ed9d9d\">red</span>, and successful updates are greeted with a central <span style=\"color: #7ac142\">green</span> checkmark. So get browsing!\n");
      out.write("\t\t\t\t\t</p>\n");
      out.write("\t\t\t\t</div>\n");
      out.write("\t\t\t\t\n");
      out.write("\t\t\t\t");
 } else if (!qResults.next()) { 
      out.write("\n");
      out.write("\t\t\t\t");
 hasResults = false; 
      out.write("\n");
      out.write("\n");
      out.write("\t\t\t\t<div class=\"jumbotron no-results-cta\">\n");
      out.write("\t  \t\t\t\t<h1 class=\"display-4\">No Results...</h1>\n");
      out.write("\t    \t\t\t<p class=\"lead\">We could not find any results matching your query. Check back later for those results, or try a different query that you think will work.</p>\n");
      out.write("\t\t\t\t</div>\n");
      out.write("\n");
      out.write("\t\t\t\t");
 } else { 
      out.write("\n");
      out.write("\t\t\t\t");
 hasResults = true; 
      out.write("\n");
      out.write("\n");
      out.write("\t\t\t\t<div id=\"main-container\">\n");
      out.write("\t\t\t\t<table id=\"info-table\" class=\"table table-striped\" data-table_type='");
      out.print( queryOption );
      out.write("'>\n");
      out.write("\t\t\t\t\t<thead>\n");
      out.write("\t\t\t\t\t\t<tr>\n");
      out.write("\t\t\t\t\t\t\t");
 if (queryOption.equals("Students") || queryOption.equals("Faculty")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Name</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Email</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Date of Birth</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Address</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Level</th>\n");
      out.write("\t\t\t\t\t\t\t");
 } else if (queryOption.equals("Courses")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Description</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Level</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Semester</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Instructor</th>\n");
      out.write("\t\t\t\t\t\t\t");
 } else if (queryOption.equals("Enrollments")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Student</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Student Email</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Course Description</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Course Level</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Semester</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Instructor</th>\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\">Grade</th>\n");
      out.write("\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<th scope=\"col\" style=\"min-width: 75px\"></th>\n");
      out.write("\t\t\t\t\t\t</tr>\n");
      out.write("\t\t\t\t\t</thead>\n");
      out.write("\t\t\t\t\t<tbody>\n");
      out.write("\t\t\t\t\t\t");
 do { 
      out.write("\n");
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\n");
      out.write("\t\t\t\t\t\t\t");
 if (queryOption.equals("Students") || queryOption.equals("Faculty")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t");
 if (queryOption.equals("Students")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<tr data-pk_attr='");
      out.print( qResults.getString("student_id") );
      out.write("'>\n");
      out.write("\t\t\t\t\t\t\t");
 } else { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<tr data-pk_attr='");
      out.print( qResults.getString("faculty_id") );
      out.write("'>\n");
      out.write("\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data name-field\" type='text' value='");
      out.print( qResults.getString("name") );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data email-field\" type-'text' value='");
      out.print( qResults.getString("email") );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data date-field\" type='text' value='");
      out.print( dateDisplayF.format(qResults.getDate("date_of_birth")) );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data address-field\" type='text' value='");
      out.print( qResults.getString("address") );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 if (queryOption.equals("Students")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"ugrad\" ");
 if(qResults.getString("level").equals("ugrad")) out.println("selected"); 
      out.write(">ugrad</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"grad\" ");
 if(qResults.getString("level").equals("grad")) out.println("selected"); 
      out.write(">grad</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 } else { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"Prof\" ");
 if(qResults.getString("level").equals("Professor")) out.println("selected"); 
      out.write(">Professor</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"AP\" ");
 if(qResults.getString("level").equals("Associate Professor")) out.println("selected"); 
      out.write(">Associate Professor</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"Instr\" ");
 if(qResults.getString("level").equals("Instructor")) out.println("selected"); 
      out.write(">Instructor</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t");
 } else if (queryOption.equals("Courses")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t");
 instructorNames.first(); 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<tr data-pk_attr='");
      out.print( qResults.getString("course_id") );
      out.write("'>\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data desc-field\" type='text' value='");
      out.print( qResults.getString("description") );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"ugrad\" ");
 if(qResults.getString("level").equals("ugrad")) out.println("selected"); 
      out.write(">ugrad</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"grad\" ");
 if(qResults.getString("level").equals("grad")) out.println("selected"); 
      out.write(">grad</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t<td><input class=\"iudb-data semester-field\" type='text' value='");
      out.print( qResults.getString("semester") );
      out.write("' disabled autocomplete=\"off\"></td>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 while(instructorNames.next()) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value='");
      out.print( instructorNames.getString("faculty_id") );
      out.write("' \n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
 if(instructorNames.getString("name").equals(qResults.getString("instructor"))) out.println("selected"); 
      out.write(">\n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
      out.print( instructorNames.getString("name") );
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t</option>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t");
 } else if (queryOption.equals("Enrollments")) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t");
 allStudents.first(); 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t");
 allCourses.first(); 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<tr data-pk_attr='");
      out.print( qResults.getString("student_id") + "," + qResults.getString("course_id") );
      out.write("'>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field uneditable\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 while(allStudents.next()) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value='");
      out.print( allStudents.getString("student_id") );
      out.write("'\n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
 if(allStudents.getString("name").equals(qResults.getString("name"))) out.println("selected"); 
      out.write(">\n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
      out.print( allStudents.getString("name") );
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t</option>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t<td>");
      out.print( qResults.getString("email") );
      out.write("</td>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field uneditable\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 while(allCourses.next()) { 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value='");
      out.print( allCourses.getString("course_id") );
      out.write("'\n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
 if(allCourses.getString("description").equals(qResults.getString("course_description"))) out.println("selected"); 
      out.write(">\n");
      out.write("\t\t\t\t\t\t\t\t\t\t\t");
      out.print( allCourses.getString("description") );
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t\t</option>\n");
      out.write("\t\t\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t<td>");
      out.print( qResults.getString("course_level") );
      out.write("</td>\n");
      out.write("\t\t\t\t\t\t\t<td>");
      out.print( qResults.getString("semester") );
      out.write("</td>\n");
      out.write("\t\t\t\t\t\t\t<td>");
      out.print( qResults.getString("instructor") );
      out.write("</td>\n");
      out.write("\t\t\t\t\t\t\t<td>\n");
      out.write("\t\t\t\t\t\t\t\t<select class=\"iudb-data custom-select options-field\" disabled>\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"A\" ");
 if(qResults.getString("grade").equals("A")) out.println("selected"); 
      out.write(">A</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"B\" ");
 if(qResults.getString("grade").equals("B")) out.println("selected"); 
      out.write(">B</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"C\" ");
 if(qResults.getString("grade").equals("C")) out.println("selected"); 
      out.write(">C</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"D\" ");
 if(qResults.getString("grade").equals("D")) out.println("selected"); 
      out.write(">D</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t\t<option value=\"F\" ");
 if(qResults.getString("grade").equals("F")) out.println("selected"); 
      out.write(">F</option>\t\n");
      out.write("\t\t\t\t\t\t\t\t</select>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\t\t\t\t\t\t\t");
 } 
      out.write("\n");
      out.write("\n");
      out.write("\t\t\t\t\t\t\t<td class=\"row-actions\">\n");
      out.write("\t\t\t\t\t\t\t\t<a href=\"#\" class=\"edit-button\">\n");
      out.write("\t\t\t\t\t\t \t\t<i class=\"fas fa-pencil-alt\" style=\"color: #b3b35f; height: 2em;\"></i>\n");
      out.write("\t\t\t\t\t\t\t\t</a>\n");
      out.write("\t\t\t\t\t\t\t\t<a href=\"#\" class=\"remove-button\">\n");
      out.write("\t\t\t\t\t\t\t\t<i class=\"fas fa-minus-circle\" style=\"color: #e04b4b; height: 2em;\"></i>\n");
      out.write("\t\t\t\t\t\t\t\t</a>\n");
      out.write("\t\t\t\t\t\t\t</td>\n");
      out.write("\n");
      out.write("\t\t\t\t\t\t\t</tr>\n");
      out.write("\t\t\t\t\t\t");
 } while (qResults.next()); 
      out.write("\n");
      out.write("\t\t\t\t\t</tbody>\n");
      out.write("\t\t\t\t</table>\n");
      out.write("\t\t\t</div>\n");
      out.write("\n");
      out.write("\t\t\t<div id=\"data-options\">\n");
      out.write("\t\t\t\t<button type=\"button\" class=\"btn btn-light btn-lg new-row-button\">Add a New Row</button>\n");
      out.write("\t\t\t\t<button type=\"button\" class=\"btn btn-primary btn-lg disabled new-changes-button\">Commit Changes</button>\n");
      out.write("\t\t\t</div>\n");
      out.write("\t\t\t");
 } 
      out.write("\n");
      out.write("\t\t</div>\n");
      out.write("\t</div>\n");
      out.write("\n");
      out.write("<div class=\"modal fade\" id=\"confirm-modal\" tabindex=\"-1\" role=\"dialog\" aria-hidden=\"true\">\n");
      out.write("\t<div class=\"modal-dialog modal-dialog-centered\" role=\"document\">\n");
      out.write("    \t<div class=\"modal-content\" style=\"background-color: #e1e1e1cc\">\n");
      out.write("\t    \t<div class=\"modal-header\" style=\"border-bottom: 0;\">\n");
      out.write("\t\t    \t<h5 class=\"modal-title\" style=\"margin: 0 auto; font-size: 20pt;\">Confirm Delete?</h5>\n");
      out.write("\t\t     </div>\n");
      out.write("\t\t\t <div class=\"modal-body\" style=\"font-size: 13pt;\">\n");
      out.write("\t\t\t \tAre you sure you wish to delete this row? The data cannot be recovered after the delete operation has completed.\n");
      out.write("\t\t\t </div>\n");
      out.write("\t\t\t <div class=\"modal-footer\" style=\"border-top: 0;\">\n");
      out.write("\t\t\t \t<button type=\"button\" class=\"btn btn-secondary exit-opt\" data-dismiss=\"modal\">Close</button>\n");
      out.write("\t\t\t    <button type=\"button\" class=\"btn btn-danger confirm-opt\">Delete</button>\n");
      out.write("\t\t\t </div>\n");
      out.write("\t\t </div>\n");
      out.write("\t </div>\n");
      out.write("</div>\n");
      out.write("</body>\n");
      out.write("\n");
      out.write("<script src=\"https://code.jquery.com/jquery-3.3.1.min.js\" integrity=\"sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=\" crossorigin=\"anonymous\"></script>\n");
      out.write("<script src=\"https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js\" integrity=\"sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q\" crossorigin=\"anonymous\"></script>\n");
      out.write("<script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js\" integrity=\"sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl\" crossorigin=\"anonymous\"></script>\n");
      out.write("<script src=\"https://cdnjs.cloudflare.com/ajax/libs/lodash.js/1.3.1/lodash.compat.min.js\"></script>\n");
      out.write("\n");
      out.write("<script type=\"application/javascript\">\n");
      out.write("\tArray.prototype.dupDiff = function(a) {\n");
      out.write("\t\tvar min = _.min([a.length, this.length]);\n");
      out.write("\t\tvar diff = [];\n");
      out.write("\t\tfor (var i = 0; i < min; i++) {\n");
      out.write("\t\t\tif (this[i] !== a[i]) {\n");
      out.write("\t\t\t\tdiff = diff.concat([this[i], a[i]]);\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\treturn diff;\n");
      out.write("\t};\n");
      out.write("\n");
      out.write("\tvar edited = [];\n");
      out.write("\tvar oldValues = [];\n");
      out.write("\tvar insertCount = 0;\n");
      out.write("\tvar errorDetected = false;\n");
      out.write("\n");
      out.write("\t$(function() {\n");
      out.write("\t\tif($(\"#success-box\").length) {\n");
      out.write("\t\t\tsetTimeout(function() {\n");
      out.write("\t\t\t\t$(\"#success-box svg\").animate({width: 0, height: 0}, 200, function() {\n");
      out.write("\t\t\t\t\t$(\"#success-box\").remove();\n");
      out.write("\t\t\t\t});\n");
      out.write("\t\t\t}, 2000);\n");
      out.write("\t\t}\n");
      out.write("\t\t$(\"#info-table tbody > tr\").each(function(idx, el) {\n");
      out.write("\t\t\t$(el).find(\"td > .iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\toldValues.push($(el).val());\n");
      out.write("\t\t\t});\n");
      out.write("\t\t});\n");
      out.write("\n");
      out.write("\t\tvar newValues = oldValues.slice();\n");
      out.write("\n");
      out.write("\t\tvar searchFilter = $(\"#search-filter > .dropdown-toggle\").text();\n");
      out.write("\n");
      out.write("\t\t$(\"input[name='queryOptions'][value='\" + searchFilter + \"']\").prop(\"checked\", true);\n");
      out.write("\n");
      out.write("\t\t$(\"#nav-menu .list-group-item\").on(\"click\", menuItemHandler);\n");
      out.write("\t\t\n");
      out.write("\t\t$(\"#search-filter .dropdown-item\").on(\"click\", searchFilterHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"#search-field\").on(\"keydown\", searchFieldKeyHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"#logout-button\").on(\"click\", logoutHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"#home-link\").on(\"click\", homeLinkHandler);\n");
      out.write("\n");
      out.write("\t\t$(\".edit-button\").on(\"click\", editButtonHandler);\n");
      out.write("\n");
      out.write("\t\t$(\".remove-button\").on(\"click\", removeButtonHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"td > input\").on(\"keydown\", formInputHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"td > select\").on(\"change\", formSelectHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"#data-options > .new-changes-button\").on(\"click\", commitChangeHandler);\n");
      out.write("\n");
      out.write("\t\t$(\"#data-options > .new-row-button\").on(\"click\", newRowHandler);\n");
      out.write("\n");
      out.write("\t\t$(\".date-field\").on(\"keydown\", dateFieldHandler);\n");
      out.write("\n");
      out.write("\t\t/* Validators */\n");
      out.write("\t\tfunction validateName(name) {\n");
      out.write("\t\t\treturn name && name.length > 0;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction validateEmail(email) {\n");
      out.write("\t\t\treturn email && email.length > 0 && /^.*@.*\\.[0-9A-Za-z]{2,6}/.test(email);\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction validateDescription(desc) {\n");
      out.write("\t\t\treturn desc && desc.length > 0;\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction validateDate(date) {\n");
      out.write("\t\t\treturn date && date.length == 10 && /^(0?[1-9]|1[012])[\\/\\-](0?[1-9]|[12][0-9]|3[01])[\\/\\-]\\d{4}$/.test(date);\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction inputFieldValidation(idx, el) {\n");
      out.write("\t\t\tvar fieldVal = $(el).val();\n");
      out.write("\t\t\tif(($(el).hasClass(\"name-field\") && !validateName(fieldVal)) ||\n");
      out.write("\t\t\t\t$(el).hasClass(\"email-field\") && !validateEmail(fieldVal) || \n");
      out.write("\t\t\t\t$(el).hasClass(\"desc-field\") && !validateDescription(fieldVal) ||\n");
      out.write("\t\t\t\t$(el).hasClass(\"date-field\") && !validateDate(fieldVal)) \n");
      out.write("\t\t\t{\n");
      out.write("\t\t\t\terrorDetected = true;\n");
      out.write("\t\t\t\t$(el).addClass(\"invalid-field\");\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t/* Event handlers */\n");
      out.write("\t\tfunction editButtonHandler() {\n");
      out.write("\t\t\tvar $row = $(this).parent(\"td\").parent();\n");
      out.write("\t\t\tvar $tbody = $row.parent();\n");
      out.write("\t\t\t\n");
      out.write("\t\t\tdisableAllInputs();\n");
      out.write("\n");
      out.write("\t\t\t$row.find(\".iudb-data:disabled\").each(function(idx, el) {\n");
      out.write("\t\t\t\tif(!$(el).hasClass(\"uneditable\")) $(el).prop(\"disabled\", false);\n");
      out.write("\t\t\t});\n");
      out.write("\n");
      out.write("\t\t\t$row.find(\"input\").first().focus();\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction removeButtonHandler() {\n");
      out.write("\t\t\tvar $row = $(this).parent(\"td\").parent();\n");
      out.write("\t\t\tvar $tbody = $row.parent();\n");
      out.write("\n");
      out.write("\t\t\tdisableAllInputs();\n");
      out.write("\n");
      out.write("\t\t\tif($row.hasClass(\"new-data-row\")) {\n");
      out.write("\t\t\t\t$row.remove();\n");
      out.write("\t\t\t\treturn;\n");
      out.write("\t\t\t}\n");
      out.write("\n");
      out.write("\t\t\t$(\"#confirm-modal\").modal();\n");
      out.write("\n");
      out.write("\t\t\t$(\"#confirm-modal button.confirm-opt\").on(\"click\", function() {\n");
      out.write("\t\t\t\tvar type = $(\"#info-table\").data(\"table_type\");\n");
      out.write("\t\t\t\tvar pk = $row.data(\"pk_attr\");\n");
      out.write("\t\t\t\tvar $form = $(\"<form method='POST' action='home.jsp' hidden></form>\");\n");
      out.write("\t\t\t\t$form.append(\"<input type='text' name='deleteType' value='\" + type + \"'>\");\n");
      out.write("\t\t\t\t$form.append(\"<input type='text' name='primaryKey' value='\" + pk + \"'>\");\n");
      out.write("\n");
      out.write("\t\t\t\t$form.prependTo(document.body);\n");
      out.write("\t\t\t\t$form.submit();\n");
      out.write("\t\t\t});\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction menuItemHandler() {\n");
      out.write("\t\t\t$(\"input[name='queryOptions'][value='\" + $(this).text() + \"']\").prop(\"checked\", true);\n");
      out.write("\t\t\t$(\"input[name='wasSearch']\").val(false);\n");
      out.write("\t\t\t$(\"#search-field\").val(\"\");\t\n");
      out.write("\t\t\t$(\"#query-form\").submit();\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction searchFilterHandler() {\n");
      out.write("\t\t\t$(\"#search-filter > .dropdown-toggle\").text($(this).text());\n");
      out.write("\t\t\tsearchFilter = $(this).text();\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction searchFieldKeyHandler(ev) {\n");
      out.write("\t\t\tif (ev.which == 13) {\n");
      out.write("\t\t\t\t$(\"input[name='queryOptions'][value='\" + searchFilter + \"']\").prop(\"checked\", true);\n");
      out.write("\t\t\t\t$(\"input[name='wasSearch']\").val(true);\n");
      out.write("\t\t\t\t$(\"#query-form\").submit();\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction logoutHandler() {\n");
      out.write("\t\t\twindow.location.href = \"/logout.jsp\";\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction homeLinkHandler() {\n");
      out.write("\t\t\twindow.location.href = \"/home.jsp\";\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction formInputHandler(ev) {\n");
      out.write("\t\t\tif (ev.which == 13) {\n");
      out.write("\t\t\t\tcheckDataChange(this);\t\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction formSelectHandler() {\n");
      out.write("\t\t\tcheckDataChange(this);\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction commitChangeHandler() {\n");
      out.write("\t\t\tif (edited.length > 0 || insertCount > 0) {\n");
      out.write("\n");
      out.write("\t\t\t\t// Edited field validation\n");
      out.write("\t\t\t\tfor (var i = 0; i < edited.length; i++)\n");
      out.write("\t\t\t\t\t$(\"#info-table tbody > tr[data-pk_attr='\" + edited[i] + \"'] .iudb-data\").each(inputFieldValidation);\n");
      out.write("\n");
      out.write("\t\t\t\t// New entry field validation\n");
      out.write("\t\t\t\tfor (var i = 0; i < insertCount; i++)\n");
      out.write("\t\t\t\t\t$(\"#info-table tbody > tr[data-new_entry=\" + (i+1) + \"] .iudb-data\").each(inputFieldValidation);\n");
      out.write("\n");
      out.write("\t\t\t\tif (errorDetected) return;\n");
      out.write("\t\t\t\t\n");
      out.write("\t\t\t\t//... after validating\n");
      out.write("\t\t\t\tvar type = $(\"#info-table\").data(\"table_type\");\n");
      out.write("\t\t\t\tvar $form = $(\"<form method='POST' action='home.jsp' hidden></form>\");\n");
      out.write("\n");
      out.write("\t\t\t\t$form.append(\"<input type='text' name='updateType' value='\" + type + \"'>\");\n");
      out.write("\n");
      out.write("\t\t\t\t// For edited rows...\n");
      out.write("\t\t\t\tfor (var i = 0; i < edited.length; i++) {\n");
      out.write("\t\t\t\t\tvar values = [];\n");
      out.write("\t\t\t\t\t$(\"#info-table tr[data-pk_attr='\" + edited[i] + \"'] .iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\t\t\tif ($(el).hasClass(\"row-action\")) return true;\n");
      out.write("\t\t\t\t\t\tvalues.push($(el).val());\t\n");
      out.write("\t\t\t\t\t});\n");
      out.write("\n");
      out.write("\t\t\t\t\t$form.append(\"<input type='text' name='\" + edited[i] + \"' value='\" + values.join(\",\") + \"'>\");\n");
      out.write("\t\t\t\t}\n");
      out.write("\n");
      out.write("\t\t\t\t// For newly inserted rows...\n");
      out.write("\t\t\t\tfor (var i = 0; i < insertCount; i++) {\n");
      out.write("\t\t\t\t\tvar values = [];\n");
      out.write("\t\t\t\t\t$(\"#info-table tr[data-new_entry=\" + (i+1) + \"] .iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\t\t\tif ($(el).hasClass(\"row-action\")) return true;\n");
      out.write("\t\t\t\t\t\tvalues.push($(el).val());\t\n");
      out.write("\t\t\t\t\t});\n");
      out.write("\n");
      out.write("\t\t\t\t\t$form.append(\"<input type='text' name='newEntry\" + (i+1) + \"' value='\" + values.join(\",\") + \"'>\");\n");
      out.write("\t\t\t\t}\n");
      out.write("\n");
      out.write("\t\t\t\t$form.prependTo(document.body);\n");
      out.write("\n");
      out.write("\t\t\t\t$form.submit();\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction newRowHandler() {\n");
      out.write("\t\t\t$(\"#main-container\").animate({ scrollTop: $('#main-container').prop(\"scrollHeight\")}, 200);\n");
      out.write("\t\t\tvar $trClone = $(\"#info-table tbody > tr:last-child\").clone();\n");
      out.write("\t\t\t$trClone.appendTo(\"#info-table tbody\");\n");
      out.write("\n");
      out.write("\t\t\t$trClone.removeAttr(\"data-pk_attr\");\n");
      out.write("\t\t\t$trClone.attr(\"data-new_entry\", ++insertCount);\n");
      out.write("\t\t\t$trClone.addClass(\"new-data-row\");\n");
      out.write("\n");
      out.write("\t\t\t$trClone.find(\".row-actions .edit-button\").on(\"click\", editButtonHandler);\n");
      out.write("\t\t\t$trClone.find(\".row-actions .remove-button\").on(\"click\", removeButtonHandler);\n");
      out.write("\n");
      out.write("\t\t\t$trClone.find(\"td\").each(function(idx, el) {\n");
      out.write("\t\t\t\tif($(el).find(\"input\").length) {\n");
      out.write("\t\t\t\t\tvar $inpEl = $(el).find(\"input\");\n");
      out.write("\t\t\t\t\t$inpEl.val(\"\");\n");
      out.write("\t\t\t\t\t$inpEl.on(\"keydown\", formInputHandler);\n");
      out.write("\t\t\t\t\tif($inpEl.hasClass(\"date-field\")) {\n");
      out.write("\t\t\t\t\t\t$inpEl.on(\"keydown\", dateFieldHandler);\n");
      out.write("\t\t\t\t\t}\n");
      out.write("\t\t\t\t} else if($(el).find(\"select\").length) {\n");
      out.write("\t\t\t\t\tvar $selEl = $(el).find(\"select\");\t\n");
      out.write("\t\t\t\t\t$selEl.on(\"change\", formSelectHandler);\n");
      out.write("\t\t\t\t\tif($selEl.hasClass(\"uneditable\")) $selEl.removeClass(\"uneditable\");\n");
      out.write("\t\t\t\t} else if(!$(el).hasClass(\"row-actions\")) {\n");
      out.write("\t\t\t\t\tel.textContent = \"\";\n");
      out.write("\t\t\t\t}\n");
      out.write("\t\t\t});\t\n");
      out.write("\n");
      out.write("\t\t\t$trClone.find(\".row-actions .edit-button\").click();\n");
      out.write("\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction dateFieldHandler(ev) {\n");
      out.write("\t\t\t$(this).val($(this).val().replace(/^(\\d{2})(\\d{2})(\\d{3})$/, \"$1-$2-$3\"));\n");
      out.write("\t\t\treturn /Arrow.*/.test(ev.key) || ev.key.includes(\"Tab\") || ev.which == 8 || ($(this).val().length < 10 && /[0-9]/.test(String.fromCharCode(ev.which)));\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\t/* Helpers */\n");
      out.write("\t\tfunction checkDataChange(el) {\n");
      out.write("\t\t\t$(\".invalid-field\").removeClass(\"invalid-field\");\n");
      out.write("\t\t\terrorDetected = false;\n");
      out.write("\t\t\t\t\n");
      out.write("\t\t\tvar $row = $(el).parent(\"td\").parent();\n");
      out.write("\t\t\tvar arrStartIdx = $row.index() * ($row.find(\".iudb-data\").length)\n");
      out.write("\n");
      out.write("\t\t\t$row.find(\".iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\t$(el).prop(\"disabled\", true);\n");
      out.write("\t\t\t\tif($(el).is(\"input\")) el.setSelectionRange(0, 0);\n");
      out.write("\t\t\t\tnewValues[arrStartIdx + idx] = $(el).val();\n");
      out.write("\t\t\t});\n");
      out.write("\n");
      out.write("\t\t\tif($row.hasClass(\"new-data-row\")) {\n");
      out.write("\t\t\t\tvar newValueCount = 0;\n");
      out.write("\t\t\t\t$row.find(\".iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\t\tif($(el).val()) ++newValueCount;\n");
      out.write("\t\t\t\t});\n");
      out.write("\n");
      out.write("\t\t\t\tif (newValueCount == 0) {\n");
      out.write("\t\t\t\t\t$row.remove();\n");
      out.write("\t\t\t\t\t--insertCount;\n");
      out.write("\t\t\t\t}\n");
      out.write("\t\t\t}\n");
      out.write("\n");
      out.write("\t\t\tvar changed = oldValues.dupDiff(newValues);\n");
      out.write("\t\t\tif (changed.length > 0 || insertCount > 0) {\n");
      out.write("\t\t\t\t$(\".new-changes-button\").removeClass(\"disabled\");\t\n");
      out.write("\t\t\t\tif ($row.data(\"pk_attr\"))\n");
      out.write("\t\t\t\t\tedited.push($row.data(\"pk_attr\"));\n");
      out.write("\t\t\t} else {\n");
      out.write("\t\t\t\t$(\".new-changes-button\").addClass(\"disabled\");\n");
      out.write("\t\t\t}\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t\tfunction disableAllInputs() {\n");
      out.write("\t\t\t$(\"#info-table tbody\").find(\"tr\").each(function(idx, el) {\n");
      out.write("\t\t\t\t$(el).find(\".iudb-data\").each(function(idx, el) {\n");
      out.write("\t\t\t\t\t$(el).prop(\"disabled\", true);\n");
      out.write("\t\t\t\t\tif($(el).is(\"input\"))\n");
      out.write("\t\t\t\t\t\tel.setSelectionRange(0, 0);\n");
      out.write("\t\t\t\t});\n");
      out.write("\t\t\t});\n");
      out.write("\t\t}\n");
      out.write("\n");
      out.write("\t});\n");
      out.write("</script>\n");
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
