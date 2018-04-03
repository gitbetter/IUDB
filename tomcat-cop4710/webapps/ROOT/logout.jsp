<%@ page import="java.sql.*, java.io.*, crypt.BCrypt, java.util.UUID"%>

<%!
	public void goToLoginPage(HttpServletResponse response) {
		try {
			response.sendRedirect(response.encodeRedirectURL("/login.jsp"));
		} catch (IOException ex) { System.out.println(ex); }
	}

	public void logUserOut(HttpSession session) {
		session.removeAttribute("session_token");
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

	if(isLoggedIn(connection, session)) {
		logUserOut(session);
		goToLoginPage(response);
	}
%>
