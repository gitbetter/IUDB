<%@ page import="java.sql.*, java.io.*, crypt.BCrypt, java.util.UUID"%>

<%!
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
%>

<%
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
%>

<html>
<head>
	<title>IUDB - Internet University Database</title>
	<meta charset="UTF-8">
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
	<link href="https://fonts.googleapis.com/css?family=Abril+Fatface" rel="stylesheet">
	<style type="text/css">
		html {
			background-image: url('images/books.jpg');
			background-size: cover;
			background-repeat: no-repeat;
			background-position: 0 0;
		}

		html, body {
			width: 100%; height: 100%;
			overflow: hidden;
			background-color: transparent;
		}

		.divider-text {
			text-align: center;
			font-size: 12pt;
			font-family: "Helvetica";
			font-weight: 200;
			color: rgba(0, 0, 0, 0.57);
			display: inline-block;
			margin: 0 20px;
		}

		.error-label {
			color: #5E322D;
			font-size: 10pt;
			font-family: "Helvetica";
			position: absolute;
			width: 100%;
			bottom: 10px;
			left: 0;
			text-align: center;
		}

		#form-container {
			position: relative;
			background: #CABCAA;
			width: 25%;
			height: auto;
			float: left;
			left: 30px;
			top: 30px;
			border-radius: 5px;
			border: 4px solid #5E322D;
			padding: 20px;
			overflow: hidden;
		}

		#form-container > h3 {
			font-family: "Helvetica";
			font-size: 14pt;
			text-align: center;
		}

		#login-form {
			position: relative;
			width: 100%; height: auto;			
		}		

		#login-form > input[type="text"],
		#login-form > input[type="password"] {
			position: relative;
			width: 75%; height: 30px;
			background-color: rgba(255, 255, 255, 0.4);
			border: none;
			border-radius: 5px;
			text-align: center;
			font-family: "Helvetica";
			font-size: 16pt;
			display: block;
			margin: 0 auto;
			margin-top: 25px;
			margin-bottom: 15px;
		}

		#login-form-buttons > input[type="submit"] {
			position: relative;
			width: 30%; height: 100%;
			background-color: rgba(255, 255, 255, 0.4);
			border: none;
			border: 1px solid #5E322D;
			border-radius: 3px;
			font-size: 12pt;
			font-family: "Helvetica"
		}

		#login-form-buttons {
			position: relative;
			text-align: center;
			margin: 35px;
			height: 30px;
		}

		#site-header {
			position: relative;
			width: 100%;
			text-align: center;
			padding: 20px;
			font-family: "Abril Fatface", cursive;
			font-size: 28pt;
		}
	</style>
</head>

<body>
	<div id="form-container">
		<h2 id="site-header">IUDB</h2>
		<h3 style="color: rgba(0, 0, 0, 0.6);">Log in or create an account to access the internet university database.</h3>
		<form id="login-form" method="POST" action="login.jsp">
			<input type="text" name="username" placeholder="Username">
			<input type="password" name="password" placeholder="Password">
			<div id="login-form-buttons">
				<input type="submit" name="login_button" value="Log In">
				<p class="divider-text">OR</p>			
				<input type="submit" name="signup_button" value="Sign Up">
			</div>
		</form>
		<% if(errorText != null) { %>
		<p class="error-label"><%= errorText %></p>
		<% } %>
	</div>
</body>
</html>
