<%@ page import="java.io.*, java.util.Enumeration, java.text.DateFormat, java.text.SimpleDateFormat, java.text.ParseException, java.sql.*"%>

<%!
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
%>

<%
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
%>

<html>
<head>
	<title>IUDB - HOME</title>
	<meta charset="UTF-8">
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css?family=Abril+Fatface" rel="stylesheet">
	<script defer src="https://use.fontawesome.com/releases/v5.0.9/js/all.js" integrity="sha384-8iPTk2s/jMVj81dnzb/iFR2sdA7u06vHJyyLlAd4snFpCl/SnyUjRrbdJsw1pGIl" crossorigin="anonymous"></script>
	<style type="text/css">
		html, body {
			width: 100%; height: 100%;
			overflow: hidden;
			background-color: transparent;
		}

		input[type="text"], *:focus {
			box-shadow: none !important;
		}

		a { 
			text-decoration: none !important;
		}

		.content-container {
			height: 100%;
		}

		.no-results-cta {
			margin-bottom: 0;
		}

		#nav-menu {
			position: relative;
		}

		#nav-menu > a {
			text-align: center;
			font-family: "Helvetica";
			border: none;
		}

		#nav-menu-container {
			height: 100%;
			padding: 0;
			border-right: 1px solid lightgray;
		}	

		#site-header {
			position: relative;
			width: 100%;
			text-align: center;
			padding: 20px;
			font-family: "Abril Fatface", cursive;
			font-size: 26pt;
		}

		#logout-button {
			background-color: #f8f9fa;
		}

		#user-menu {
			position: absolute;
			bottom: 0;
			left: 0;
			width: 100%;
			text-align: center;
		}

		#user-menu > a {
			border: none;
		}

		#query-form {
			width: 100%;
		}

		#query-form > .input-group {
			margin: 0;
			border-bottom: 1px solid lightgray;
		}

		#search-filter {
			display: inline-block;
		}

		#search-filter > .dropdown-toggle {
			background-color: #f8f8f8;
			color: gray;
			border: none;
			height: 100%;
			margin-right: 1px;
			border-right: 1px solid lightgray;
		}

		#search-filter .dropdown-menu {
			padding: 0;
			margin-top: 1px;
			border-radius: 0;
			border-left: 0;
			border-top: 0;
			box-shadow: 0px 0px 5px lightgray;
		}

		#search-filter .dropdown-menu > .dropdown-item {
			text-align: center;
		}

		#search-field {
			border: none;	
			font-size: 18pt;
			padding: 10px 10px 10px 30px;
			font-family: "Helvetica";
		}

		#main-container {
			width: 100%; max-height: 70%;
			overflow-y: scroll;
			border-top: 1px solid lightgray;
			border-bottom: 1px solid lightgray;
		}

		.welcome-cta, .no-results-cta {
			position: relative;
			top: 14%;
			width: 75%;
			margin: 0 auto;
			background-color: #f8f8f8;
		}

		.welcome-cta > h1,
		.no-results-cta > h1 {
			color: #000000b3;
			font-family: 'Abril Fatface', cursive;
			text-align: center;
		}

		#info-table {
			width: 100%;
			margin: 0 auto;
		}

		#info-table > thead th,
		#info-table > tbody td {
			padding: 20px;
		}

		#info-table > thead th {
	    	font-weight: 400;
		    font-family: Helvetica;
			border-top: none;
		}

		#info-table > tbody td {
		    font-family: Helvetica;
			padding: 10px;
			vertical-align: middle;
		}

		#info-table > tbody td > input {
			border: none;
			background-color: #b9b9b933;
			padding: 10px;
			text-overflow: ellipsis;
			overflow: hidden;
		}

		#info-table > tbody td > input:disabled {
			background-color: transparent;
			color: black;
		}

		#data-options {
			text-align: center;
			padding: 20px;
		}

		#data-options > button {
			width: 46%;
			height: 60px;
			border-radius: 0;
		}

		#home-link {
			color: black;
		}

		.edit-button, .remove-button {
			padding: 10px;
		}

		.new-changes-button,
		.new-row-button {
			transition: all 200ms;
		}

		.new-changes-button.disabled {
			background-color: lightgray;
			border: lightgray;
		}

		input.invalid-field {
			border: 2px solid #ed9d9d !important;
		}

		#success-box {
			position: absolute;
			left: 50%;
			top: 40%;
			transform: translateY(-50%) translateX(-50%);
			z-index: 500;
		}

		.options-field,
		.options-field:disabled {
			border: none;
			background-color: transparent;
			color: black;
		}

		.options-field:disabled {
			background: none;
		}

		/* Success checkmark styles. Fetched from
		 * https://jsfiddle.net/Hybrid8287/gtb1avet/1/
		 * Thanks to Michael Draemel!
		 */

		.checkmark__circle {
	  		stroke-dasharray: 166;
    		stroke-dashoffset: 166;
	  		stroke-width: 2;
	    	stroke-miterlimit: 10;
		  	stroke: #7ac142;
		    fill: none;
			animation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;
		}

	    .checkmark {
		    width: 150px;
		    height: 150px;
		    border-radius: 50%;
		    display: block;
		    stroke-width: 2;
		    stroke: #fff;
	        stroke-miterlimit: 10;
			margin: 10% auto;
		    box-shadow: inset 0px 0px 0px #7ac142;
		    animation: fill .4s ease-in-out .4s forwards, scale .3s ease-in-out .9s both;
		}

		.checkmark__check {
			transform-origin: 50% 50%;
		    stroke-dasharray: 48;
		    stroke-dashoffset: 48;
		    animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;
	    }

		@keyframes stroke {
		    100% {
			    stroke-dashoffset: 0;
			}
	    }
		@keyframes scale {
		    0%, 100% {
			    transform: none;
		    }
		    50% {
			    transform: scale3d(1.1, 1.1, 1);
	     	}
	    }
	    @keyframes fill {
		    100% {
			    box-shadow: inset 0px 0px 0px 90px #7ac142;
		 	}
	    }
	</style>
</head>

<body>

	<% if (successfulUpdate) { %>
	<div id="success-box">
		<svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52"><circle class="checkmark__circle" cx="26" cy="26" r="25" fill="none"/><path class="checkmark__check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/></svg>
	</div>
	<% } %>

	<div class="content-container row">
		<div id="nav-menu-container" class="col-md-2">
			<a id="home-link" href="#"><h3 id="site-header">IUDB</h3></a>
			<div id="nav-menu" class="list-group">
		  		<a href="#" class="list-group-item list-group-item-action">Students</a>
		  		<a href="#" class="list-group-item list-group-item-action">Courses</a>
		    	<a href="#" class="list-group-item list-group-item-action">Faculty</a>
			  	<a href="#" class="list-group-item list-group-item-action">Enrollments</a>
			</div>

			<div id="user-menu">
				<a id="logout-button" href="#" class="list-group-item list-group-item-action">Log out</a>
			</div>
		</div>
		<div class="col-md-10" style="padding: 0; height: 100%">
			<form id="query-form" method="POST" action="home.jsp">
				<div class="input-group mb-3" style="margin: 0">
			  		<div id="search-filter" class="input-group-prepend">
			      		<button class="btn btn-outline-secondary dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><%= isStringSet(queryOption) ? queryOption : "Students" %></button>
				      		<div class="dropdown-menu">
					    	   	<a class="dropdown-item" href="#">Students</a>
							    <a class="dropdown-item" href="#">Courses</a>
							    <a class="dropdown-item" href="#">Faculty</a>
						 	</div>
					</div>
				    <input id="search-field" type="text" name="searchQuery" class="form-control" aria-label="Text input with dropdown button" placeholder="Search">
				</div>

				<!--Hidden form elements used as a data model-->
				<input type="radio" name="queryOptions" value="Students" hidden>
				<input type="radio" name="queryOptions" value="Faculty" hidden>
				<input type="radio" name="queryOptions" value="Courses" hidden>
				<input type="radio" name="queryOptions" value="Enrollments" hidden>
				<input type="hidden" name="wasSearch" value="false">
			</form>

				<% if (qResults == null) { %>
				<% hasResults = false; %>
				
				<div class="jumbotron welcome-cta">
	  				<h1 class="display-4">Internet University DataBase</h1>
	    			<p class="lead" style="line-height: 45px;">
						Easily find what you're looking for by using the search bar and filter at the top, or click on one of the links to the left to display categorical results.
						Add some entries by navigating to one of the categories, clicking on the <button type="button" class="btn btn-light btn-lg">Add a New Row</button> button
						filling out the new row and hitting enter. 
						Click on the  <i class="fas fa-pencil-alt" style="color: #b3b35f; height: 1em;"></i> icon of an entry to edit that row. 
						When you're ready to commit you're changes, click on the <button type="button" class="btn btn-primary btn-lg">Commit Changes</button> button to save
						your data to the <span style="font-family: 'Abril fatface', cursive">IUDB</span> database.
						Click on the  <i class="fas fa-minus-circle" style="color: #e04b4b; height: 1em;"></i>  icon to remove a row. Fields with validation errors will be outlined
						in <span style="color: #ed9d9d">red</span>, and successful updates are greeted with a central <span style="color: #7ac142">green</span> checkmark. So get browsing!
					</p>
				</div>
				
				<% } else if (!qResults.next()) { %>
				<% hasResults = false; %>

				<div class="jumbotron no-results-cta">
	  				<h1 class="display-4">No Results...</h1>
	    			<p class="lead">We could not find any results matching your query. Check back later for those results, or try a different query that you think will work.</p>
				</div>

				<% } else { %>
				<% hasResults = true; %>

				<div id="main-container">
				<table id="info-table" class="table table-striped" data-table_type='<%= queryOption %>'>
					<thead>
						<tr>
							<% if (queryOption.equals("Students") || queryOption.equals("Faculty")) { %>
							<th scope="col">Name</th>
							<th scope="col">Email</th>
							<th scope="col">Date of Birth</th>
							<th scope="col">Address</th>
							<th scope="col">Level</th>
							<% } else if (queryOption.equals("Courses")) { %>
							<th scope="col">Description</th>
							<th scope="col">Level</th>
							<th scope="col">Semester</th>
							<th scope="col">Instructor</th>
							<% } else if (queryOption.equals("Enrollments")) { %>
							<th scope="col">Student</th>
							<th scope="col">Student Email</th>
							<th scope="col">Course Description</th>
							<th scope="col">Course Level</th>
							<th scope="col">Semester</th>
							<th scope="col">Instructor</th>
							<th scope="col">Grade</th>
							<% } %>
							<th scope="col" style="min-width: 75px"></th>
						</tr>
					</thead>
					<tbody>
						<% do { %>

							
							<% if (queryOption.equals("Students") || queryOption.equals("Faculty")) { %>
							<% if (queryOption.equals("Students")) { %>
							<tr data-pk_attr='<%= qResults.getString("student_id") %>'>
							<% } else { %>
							<tr data-pk_attr='<%= qResults.getString("faculty_id") %>'>
							<% } %>
							<td><input class="iudb-data name-field" type='text' value='<%= qResults.getString("name") %>' disabled autocomplete="off"></td>
							<td><input class="iudb-data email-field" type-'text' value='<%= qResults.getString("email") %>' disabled autocomplete="off"></td>
							<td><input class="iudb-data date-field" type='text' value='<%= dateDisplayF.format(qResults.getDate("date_of_birth")) %>' disabled autocomplete="off"></td>
							<td><input class="iudb-data address-field" type='text' value='<%= qResults.getString("address") %>' disabled autocomplete="off"></td>
							<td>
								<select class="iudb-data custom-select options-field" disabled>
									<% if (queryOption.equals("Students")) { %>
									<option value="ugrad" <% if(qResults.getString("level").equals("ugrad")) out.println("selected"); %>>ugrad</option>	
									<option value="grad" <% if(qResults.getString("level").equals("grad")) out.println("selected"); %>>grad</option>	
									<% } else { %>
									<option value="Prof" <% if(qResults.getString("level").equals("Professor")) out.println("selected"); %>>Professor</option>	
									<option value="AP" <% if(qResults.getString("level").equals("Associate Professor")) out.println("selected"); %>>Associate Professor</option>	
									<option value="Instr" <% if(qResults.getString("level").equals("Instructor")) out.println("selected"); %>>Instructor</option>	
									<% } %>
								</select>
							</td>
							<% } else if (queryOption.equals("Courses")) { %>
							<% instructorNames.first(); %>
							<tr data-pk_attr='<%= qResults.getString("course_id") %>'>
							<td><input class="iudb-data desc-field" type='text' value='<%= qResults.getString("description") %>' disabled autocomplete="off"></td>
							<td>
								<select class="iudb-data custom-select options-field" disabled>
									<option value="ugrad" <% if(qResults.getString("level").equals("ugrad")) out.println("selected"); %>>ugrad</option>	
									<option value="grad" <% if(qResults.getString("level").equals("grad")) out.println("selected"); %>>grad</option>	
								</select>
							</td>
							<td><input class="iudb-data semester-field" type='text' value='<%= qResults.getString("semester") %>' disabled autocomplete="off"></td>
							<td>
								<select class="iudb-data custom-select options-field" disabled>
									<% while(instructorNames.next()) { %>
									<option value='<%= instructorNames.getString("faculty_id") %>' 
											<% if(instructorNames.getString("name").equals(qResults.getString("instructor"))) out.println("selected"); %>>
											<%= instructorNames.getString("name") %>
									</option>
									<% } %>
								</select>
							</td>
							<% } else if (queryOption.equals("Enrollments")) { %>
							<% allStudents.first(); %>
							<% allCourses.first(); %>
							<tr data-pk_attr='<%= qResults.getString("student_id") + "," + qResults.getString("course_id") %>'>
							<td>
								<select class="iudb-data custom-select options-field uneditable" disabled>
									<% while(allStudents.next()) { %>
									<option value='<%= allStudents.getString("student_id") %>'
											<% if(allStudents.getString("name").equals(qResults.getString("name"))) out.println("selected"); %>>
											<%= allStudents.getString("name") %>
									</option>
									<% } %>
								</select>
							</td>
							<td><%= qResults.getString("email") %></td>
							<td>
								<select class="iudb-data custom-select options-field uneditable" disabled>
									<% while(allCourses.next()) { %>
									<option value='<%= allCourses.getString("course_id") %>'
											<% if(allCourses.getString("description").equals(qResults.getString("course_description"))) out.println("selected"); %>>
											<%= allCourses.getString("description") %>
									</option>
									<% } %>
								</select>
							</td>
							<td><%= qResults.getString("course_level") %></td>
							<td><%= qResults.getString("semester") %></td>
							<td><%= qResults.getString("instructor") %></td>
							<td>
								<select class="iudb-data custom-select options-field" disabled>
									<option value="A" <% if(qResults.getString("grade").equals("A")) out.println("selected"); %>>A</option>	
									<option value="B" <% if(qResults.getString("grade").equals("B")) out.println("selected"); %>>B</option>	
									<option value="C" <% if(qResults.getString("grade").equals("C")) out.println("selected"); %>>C</option>	
									<option value="D" <% if(qResults.getString("grade").equals("D")) out.println("selected"); %>>D</option>	
									<option value="F" <% if(qResults.getString("grade").equals("F")) out.println("selected"); %>>F</option>	
								</select>
							</td>
							<% } %>

							<td class="row-actions">
								<a href="#" class="edit-button">
						 		<i class="fas fa-pencil-alt" style="color: #b3b35f; height: 2em;"></i>
								</a>
								<a href="#" class="remove-button">
								<i class="fas fa-minus-circle" style="color: #e04b4b; height: 2em;"></i>
								</a>
							</td>

							</tr>
						<% } while (qResults.next()); %>
					</tbody>
				</table>
			</div>

			<div id="data-options">
				<button type="button" class="btn btn-light btn-lg new-row-button">Add a New Row</button>
				<button type="button" class="btn btn-primary btn-lg disabled new-changes-button">Commit Changes</button>
			</div>
			<% } %>
		</div>
	</div>

<div class="modal fade" id="confirm-modal" tabindex="-1" role="dialog" aria-hidden="true">
	<div class="modal-dialog modal-dialog-centered" role="document">
    	<div class="modal-content" style="background-color: #e1e1e1cc">
	    	<div class="modal-header" style="border-bottom: 0;">
		    	<h5 class="modal-title" style="margin: 0 auto; font-size: 20pt;">Confirm Delete?</h5>
		     </div>
			 <div class="modal-body" style="font-size: 13pt;">
			 	Are you sure you wish to delete this row? The data cannot be recovered after the delete operation has completed.
			 </div>
			 <div class="modal-footer" style="border-top: 0;">
			 	<button type="button" class="btn btn-secondary exit-opt" data-dismiss="modal">Close</button>
			    <button type="button" class="btn btn-danger confirm-opt">Delete</button>
			 </div>
		 </div>
	 </div>
</div>
</body>

<script src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/lodash.js/1.3.1/lodash.compat.min.js"></script>

<script type="application/javascript">
	Array.prototype.dupDiff = function(a) {
		var min = _.min([a.length, this.length]);
		var diff = [];
		for (var i = 0; i < min; i++) {
			if (this[i] !== a[i]) {
				diff = diff.concat([this[i], a[i]]);
			}
		}

		return diff;
	};

	var edited = [];
	var oldValues = [];
	var insertCount = 0;
	var errorDetected = false;

	$(function() {
		if($("#success-box").length) {
			setTimeout(function() {
				$("#success-box svg").animate({width: 0, height: 0}, 200, function() {
					$("#success-box").remove();
				});
			}, 2000);
		}
		$("#info-table tbody > tr").each(function(idx, el) {
			$(el).find("td > .iudb-data").each(function(idx, el) {
				oldValues.push($(el).val());
			});
		});

		var newValues = oldValues.slice();

		var searchFilter = $("#search-filter > .dropdown-toggle").text();

		$("input[name='queryOptions'][value='" + searchFilter + "']").prop("checked", true);

		$("#nav-menu .list-group-item").on("click", menuItemHandler);
		
		$("#search-filter .dropdown-item").on("click", searchFilterHandler);

		$("#search-field").on("keydown", searchFieldKeyHandler);

		$("#logout-button").on("click", logoutHandler);

		$("#home-link").on("click", homeLinkHandler);

		$(".edit-button").on("click", editButtonHandler);

		$(".remove-button").on("click", removeButtonHandler);

		$("td > input").on("keydown", formInputHandler);

		$("td > select").on("change", formSelectHandler);

		$("#data-options > .new-changes-button").on("click", commitChangeHandler);

		$("#data-options > .new-row-button").on("click", newRowHandler);

		$(".date-field").on("keydown", dateFieldHandler);

		/* Validators */
		function validateName(name) {
			return name && name.length > 0;
		}

		function validateEmail(email) {
			return email && email.length > 0 && /^.*@.*\.[0-9A-Za-z]{2,6}/.test(email);
		}

		function validateDescription(desc) {
			return desc && desc.length > 0;
		}

		function validateDate(date) {
			return date && date.length == 10 && /^(0?[1-9]|1[012])[\/\-](0?[1-9]|[12][0-9]|3[01])[\/\-]\d{4}$/.test(date);
		}

		function inputFieldValidation(idx, el) {
			var fieldVal = $(el).val();
			if(($(el).hasClass("name-field") && !validateName(fieldVal)) ||
				$(el).hasClass("email-field") && !validateEmail(fieldVal) || 
				$(el).hasClass("desc-field") && !validateDescription(fieldVal) ||
				$(el).hasClass("date-field") && !validateDate(fieldVal)) 
			{
				errorDetected = true;
				$(el).addClass("invalid-field");
			}
		}

		/* Event handlers */
		function editButtonHandler() {
			var $row = $(this).parent("td").parent();
			var $tbody = $row.parent();
			
			disableAllInputs();

			$row.find(".iudb-data:disabled").each(function(idx, el) {
				if(!$(el).hasClass("uneditable")) $(el).prop("disabled", false);
			});

			$row.find("input").first().focus();
		}

		function removeButtonHandler() {
			var $row = $(this).parent("td").parent();
			var $tbody = $row.parent();

			disableAllInputs();

			if($row.hasClass("new-data-row")) {
				$row.remove();
				return;
			}

			$("#confirm-modal").modal();

			$("#confirm-modal button.confirm-opt").on("click", function() {
				var type = $("#info-table").data("table_type");
				var pk = $row.data("pk_attr");
				var $form = $("<form method='POST' action='home.jsp' hidden></form>");
				$form.append("<input type='text' name='deleteType' value='" + type + "'>");
				$form.append("<input type='text' name='primaryKey' value='" + pk + "'>");

				$form.prependTo(document.body);
				$form.submit();
			});
		}

		function menuItemHandler() {
			$("input[name='queryOptions'][value='" + $(this).text() + "']").prop("checked", true);
			$("input[name='wasSearch']").val(false);
			$("#search-field").val("");	
			$("#query-form").submit();
		}

		function searchFilterHandler() {
			$("#search-filter > .dropdown-toggle").text($(this).text());
			searchFilter = $(this).text();
		}

		function searchFieldKeyHandler(ev) {
			if (ev.which == 13) {
				$("input[name='queryOptions'][value='" + searchFilter + "']").prop("checked", true);
				$("input[name='wasSearch']").val(true);
				$("#query-form").submit();
			}
		}

		function logoutHandler() {
			window.location.href = "/logout.jsp";
		}

		function homeLinkHandler() {
			window.location.href = "/home.jsp";
		}

		function formInputHandler(ev) {
			if (ev.which == 13) {
				checkDataChange(this);	
			}
		}

		function formSelectHandler() {
			checkDataChange(this);
		}

		function commitChangeHandler() {
			if (edited.length > 0 || insertCount > 0) {

				// Edited field validation
				for (var i = 0; i < edited.length; i++)
					$("#info-table tbody > tr[data-pk_attr='" + edited[i] + "'] .iudb-data").each(inputFieldValidation);

				// New entry field validation
				for (var i = 0; i < insertCount; i++)
					$("#info-table tbody > tr[data-new_entry=" + (i+1) + "] .iudb-data").each(inputFieldValidation);

				if (errorDetected) return;
				
				//... after validating
				var type = $("#info-table").data("table_type");
				var $form = $("<form method='POST' action='home.jsp' hidden></form>");

				$form.append("<input type='text' name='updateType' value='" + type + "'>");

				// For edited rows...
				for (var i = 0; i < edited.length; i++) {
					var values = [];
					$("#info-table tr[data-pk_attr='" + edited[i] + "'] .iudb-data").each(function(idx, el) {
						if ($(el).hasClass("row-action")) return true;
						values.push($(el).val());	
					});

					$form.append("<input type='text' name='" + edited[i] + "' value='" + values.join(",") + "'>");
				}

				// For newly inserted rows...
				for (var i = 0; i < insertCount; i++) {
					var values = [];
					$("#info-table tr[data-new_entry=" + (i+1) + "] .iudb-data").each(function(idx, el) {
						if ($(el).hasClass("row-action")) return true;
						values.push($(el).val());	
					});

					$form.append("<input type='text' name='newEntry" + (i+1) + "' value='" + values.join(",") + "'>");
				}

				$form.prependTo(document.body);

				$form.submit();
			}
		}

		function newRowHandler() {
			$("#main-container").animate({ scrollTop: $('#main-container').prop("scrollHeight")}, 200);
			var $trClone = $("#info-table tbody > tr:last-child").clone();
			$trClone.appendTo("#info-table tbody");

			$trClone.removeAttr("data-pk_attr");
			$trClone.attr("data-new_entry", ++insertCount);
			$trClone.addClass("new-data-row");

			$trClone.find(".row-actions .edit-button").on("click", editButtonHandler);
			$trClone.find(".row-actions .remove-button").on("click", removeButtonHandler);

			$trClone.find("td").each(function(idx, el) {
				if($(el).find("input").length) {
					var $inpEl = $(el).find("input");
					$inpEl.val("");
					$inpEl.on("keydown", formInputHandler);
					if($inpEl.hasClass("date-field")) {
						$inpEl.on("keydown", dateFieldHandler);
					}
				} else if($(el).find("select").length) {
					var $selEl = $(el).find("select");	
					$selEl.on("change", formSelectHandler);
					if($selEl.hasClass("uneditable")) $selEl.removeClass("uneditable");
				} else if(!$(el).hasClass("row-actions")) {
					el.textContent = "";
				}
			});	

			$trClone.find(".row-actions .edit-button").click();

		}

		function dateFieldHandler(ev) {
			$(this).val($(this).val().replace(/^(\d{2})(\d{2})(\d{3})$/, "$1-$2-$3"));
			return /Arrow.*/.test(ev.key) || ev.key.includes("Tab") || ev.which == 8 || ($(this).val().length < 10 && /[0-9]/.test(String.fromCharCode(ev.which)));
		}

		/* Helpers */
		function checkDataChange(el) {
			$(".invalid-field").removeClass("invalid-field");
			errorDetected = false;
				
			var $row = $(el).parent("td").parent();
			var arrStartIdx = $row.index() * ($row.find(".iudb-data").length)

			$row.find(".iudb-data").each(function(idx, el) {
				$(el).prop("disabled", true);
				if($(el).is("input")) el.setSelectionRange(0, 0);
				newValues[arrStartIdx + idx] = $(el).val();
			});

			if($row.hasClass("new-data-row")) {
				var newValueCount = 0;
				$row.find(".iudb-data").each(function(idx, el) {
					if($(el).val()) ++newValueCount;
				});

				if (newValueCount == 0) {
					$row.remove();
					--insertCount;
				}
			}

			var changed = oldValues.dupDiff(newValues);
			if (changed.length > 0 || insertCount > 0) {
				$(".new-changes-button").removeClass("disabled");	
				if ($row.data("pk_attr"))
					edited.push($row.data("pk_attr"));
			} else {
				$(".new-changes-button").addClass("disabled");
			}
		}

		function disableAllInputs() {
			$("#info-table tbody").find("tr").each(function(idx, el) {
				$(el).find(".iudb-data").each(function(idx, el) {
					$(el).prop("disabled", true);
					if($(el).is("input"))
						el.setSelectionRange(0, 0);
				});
			});
		}

	});
</script>
</html>
