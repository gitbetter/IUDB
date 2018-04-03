--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.5

-- Started on 2018-04-03 18:22:22 EDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 13276)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3122 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 188 (class 1259 OID 760420)
-- Name: simulated_records; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE simulated_records (
    record_id bigint NOT NULL,
    school text NOT NULL,
    grade text NOT NULL
);


ALTER TABLE simulated_records OWNER TO spr18_asanc412;

--
-- TOC entry 209 (class 1255 OID 760433)
-- Name: assign_grades(); Type: FUNCTION; Schema: public; Owner: spr18_asanc412
--

CREATE FUNCTION assign_grades() RETURNS SETOF simulated_records
    LANGUAGE plpgsql
    AS $$
DECLARE
	-- Variables and their definitions
	school_probs_cursor CURSOR FOR SELECT * FROM school_probs;	
	stdnt_count INTEGER;
	grade_distributions INTEGER[];
	dist_sum INTEGER;
	grade_info grade_values%ROWTYPE;
	p FLOAT;
BEGIN
	/*
		Loop through each of the schools to fetch the school
		name and probability distribution
	*/

	FOR s_prob IN school_probs_cursor LOOP

		-- Make sure to clear the previous grade distribution array
		grade_distributions := ARRAY[]::INTEGER[];

		-- Get the number of students for this school
		SELECT COUNT(*) INTO stdnt_count FROM simulated_records WHERE school = s_prob.school;

		RAISE NOTICE 'student count for % is %', s_prob.school, stdnt_count;
		
		/*
			Calculate the integral grade distributions using 
			the number of students and probability distributions for
			this school.
		*/

		FOREACH p IN ARRAY s_prob.probs LOOP
			grade_distributions := array_append(grade_distributions, cast(round(p * stdnt_count) as INT));
		END LOOP;

		/*
			Check if the grade distributions sum is greater than the number
			of students, due to rounding. If so, loop through and modestly 
			decrement the worst grade until the distribution and grade counts match.
		*/

		SELECT SUM(s) INTO dist_sum FROM UNNEST(grade_distributions) s;
		RAISE NOTICE 'The total grade distribution is %.', dist_sum;
		IF dist_sum > stdnt_count THEN
			WHILE dist_sum > stdnt_count LOOP			
				grade_distributions[array_length(grade_distributions, 1)] := grade_distributions[array_length(grade_distributions, 1)] - 1;
				SELECT SUM(s) INTO dist_sum FROM UNNEST(grade_distributions) s;
				RAISE NOTICE 'The total grade distribution is %.', dist_sum;
			END LOOP;			
		END IF;	

		/*	
			Loop through each of the grade distributions,
			fetch the corresponding grade entry and use it to 
			update the value of any student that has no grade set
			and currently attends the school set by the outer loop.
			Limits the updates using the current grade distribution. 
		*/
		
		FOR i IN 1..array_length(grade_distributions, 1) LOOP			
			SELECT * INTO grade_info FROM grade_values WHERE id = i;

			RAISE NOTICE 'Grade distribution for % is %', grade_info.grade, grade_distributions[i];
			
			UPDATE simulated_records 
			SET grade = grade_info.grade 
			WHERE record_id IN 
				(SELECT record_id FROM simulated_records 
				WHERE grade = '-' AND school = s_prob.school 
				LIMIT grade_distributions[i]);	
		END LOOP;
	END LOOP;

	-- Return the updated simulated_records table
	RETURN QUERY SELECT * FROM simulated_records;
END;
$$;


ALTER FUNCTION public.assign_grades() OWNER TO spr18_asanc412;

--
-- TOC entry 189 (class 1259 OID 807846)
-- Name: _users; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE _users (
    username character varying(64) NOT NULL,
    password character varying(64) NOT NULL,
    session_token character varying(140)
);


ALTER TABLE _users OWNER TO spr18_asanc412;

--
-- TOC entry 195 (class 1259 OID 807920)
-- Name: courses_auto_id; Type: SEQUENCE; Schema: public; Owner: spr18_asanc412
--

CREATE SEQUENCE courses_auto_id
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE courses_auto_id OWNER TO spr18_asanc412;

--
-- TOC entry 183 (class 1259 OID 742238)
-- Name: courses; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE courses (
    course_id integer DEFAULT nextval('courses_auto_id'::regclass) NOT NULL,
    description text NOT NULL,
    level character varying(10) NOT NULL,
    instructor integer,
    semester character varying(16)
);


ALTER TABLE courses OWNER TO spr18_asanc412;

--
-- TOC entry 184 (class 1259 OID 742251)
-- Name: enroll; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE enroll (
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    grade character varying(2) NOT NULL
);


ALTER TABLE enroll OWNER TO spr18_asanc412;

--
-- TOC entry 196 (class 1259 OID 807922)
-- Name: faculty_auto_id; Type: SEQUENCE; Schema: public; Owner: spr18_asanc412
--

CREATE SEQUENCE faculty_auto_id
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE faculty_auto_id OWNER TO spr18_asanc412;

--
-- TOC entry 182 (class 1259 OID 742231)
-- Name: faculties; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE faculties (
    faculty_id integer DEFAULT nextval('faculty_auto_id'::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    date_of_birth date,
    address character varying(100),
    email character varying(32),
    level character varying(32) NOT NULL
);


ALTER TABLE faculties OWNER TO spr18_asanc412;

--
-- TOC entry 185 (class 1259 OID 747063)
-- Name: faculty_level; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE faculty_level (
    name character varying(64) NOT NULL,
    abbreviation character varying(6)
);


ALTER TABLE faculty_level OWNER TO spr18_asanc412;

--
-- TOC entry 187 (class 1259 OID 760412)
-- Name: grade_values; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE grade_values (
    id integer NOT NULL,
    score text NOT NULL,
    grade text NOT NULL
);


ALTER TABLE grade_values OWNER TO spr18_asanc412;

--
-- TOC entry 186 (class 1259 OID 760404)
-- Name: school_probs; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE school_probs (
    school_code bigint NOT NULL,
    school text NOT NULL,
    probs numeric[] NOT NULL
);


ALTER TABLE school_probs OWNER TO spr18_asanc412;

--
-- TOC entry 194 (class 1259 OID 807918)
-- Name: students_auto_id; Type: SEQUENCE; Schema: public; Owner: spr18_asanc412
--

CREATE SEQUENCE students_auto_id
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE students_auto_id OWNER TO spr18_asanc412;

--
-- TOC entry 181 (class 1259 OID 742224)
-- Name: students; Type: TABLE; Schema: public; Owner: spr18_asanc412
--

CREATE TABLE students (
    student_id integer DEFAULT nextval('students_auto_id'::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    date_of_birth date,
    address character varying(100),
    email character varying(32),
    level character varying(10) NOT NULL
);


ALTER TABLE students OWNER TO spr18_asanc412;

--
-- TOC entry 192 (class 1259 OID 807910)
-- Name: vcourses; Type: VIEW; Schema: public; Owner: spr18_asanc412
--

CREATE VIEW vcourses AS
 SELECT c.course_id,
    c.description,
    c.level,
    c.semester,
    i.name AS instructor
   FROM courses c,
    faculties i
  WHERE (c.instructor = i.faculty_id)
  ORDER BY c.course_id;


ALTER TABLE vcourses OWNER TO spr18_asanc412;

--
-- TOC entry 193 (class 1259 OID 807914)
-- Name: vfaculty; Type: VIEW; Schema: public; Owner: spr18_asanc412
--

CREATE VIEW vfaculty AS
 SELECT f.faculty_id,
    f.name,
    f.date_of_birth,
    f.address,
    f.email,
    fl.name AS level
   FROM faculties f,
    faculty_level fl
  WHERE ((f.level)::text = (fl.abbreviation)::text)
  ORDER BY f.faculty_id;


ALTER TABLE vfaculty OWNER TO spr18_asanc412;

--
-- TOC entry 190 (class 1259 OID 807902)
-- Name: vstudentenrollments; Type: VIEW; Schema: public; Owner: spr18_asanc412
--

CREATE VIEW vstudentenrollments AS
 SELECT s.student_id,
    s.name,
    s.date_of_birth,
    s.address,
    s.email,
    s.level AS student_level,
    c.course_id,
    c.description AS course_description,
    c.level AS course_level,
    i.name AS instructor,
    c.semester,
    e.grade
   FROM courses c,
    students s,
    enroll e,
    faculties i
  WHERE ((e.student_id = s.student_id) AND (e.course_id = c.course_id) AND (c.instructor = i.faculty_id));


ALTER TABLE vstudentenrollments OWNER TO spr18_asanc412;

--
-- TOC entry 191 (class 1259 OID 807906)
-- Name: vstudents; Type: VIEW; Schema: public; Owner: spr18_asanc412
--

CREATE VIEW vstudents AS
 SELECT s.student_id,
    s.name,
    s.date_of_birth,
    s.address,
    s.email,
    s.level
   FROM students s
  ORDER BY s.student_id;


ALTER TABLE vstudents OWNER TO spr18_asanc412;

--
-- TOC entry 3111 (class 0 OID 807846)
-- Dependencies: 189
-- Data for Name: _users; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY _users (username, password, session_token) FROM stdin;
skatehumor	$2a$12$kIvEic6CjszaGITVAp9g4urq25vZrV3ItbIGcGGVq4GXI/ocb6VXC	271c7061-d8f8-4c74-93e7-428a037f87c5
\.


--
-- TOC entry 3105 (class 0 OID 742238)
-- Dependencies: 183
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY courses (course_id, description, level, instructor, semester) FROM stdin;
1	Fundamentals of Computer Sys.	ugrad	1	Spring 2018
2	Software Engineering I	ugrad	2	Spring 2018
3	Computer Programming I	ugrad	2	Spring 2018
4	Introduction to Algorithms	grad	4	Fall 2017
5	Operating Systems	grad	5	Fall 2017
6	Software Design	grad	6	Spring 2017
7	Advanced Database	grad	5	Spring 2017
\.


--
-- TOC entry 3123 (class 0 OID 0)
-- Dependencies: 195
-- Name: courses_auto_id; Type: SEQUENCE SET; Schema: public; Owner: spr18_asanc412
--

SELECT pg_catalog.setval('courses_auto_id', 100, false);


--
-- TOC entry 3106 (class 0 OID 742251)
-- Dependencies: 184
-- Data for Name: enroll; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY enroll (student_id, course_id, grade) FROM stdin;
1	1	A
1	2	B
1	3	A
3	1	F
3	3	C
5	1	B
6	6	C
6	7	B
7	7	B
2	1	D
8	5	A
8	7	A
2	3	C
3	6	B
\.


--
-- TOC entry 3104 (class 0 OID 742231)
-- Dependencies: 182
-- Data for Name: faculties; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY faculties (faculty_id, name, date_of_birth, address, email, level) FROM stdin;
2	Thomas Taylor	1988-05-24	4467 NW 8 ST	taylt@cis.fiu.edu	Instr
1	George Blunt	1979-08-13	11345 SW 56 ST	bluns@cis.fiu.edu	Instr
6	William Parre	1976-11-22	1570 NE 127 AVE	parrw@cis.fiu.edu	AP
5	Steven Garden	1975-09-18	1277 SW 87 AVE	gards@cis.fiu.edu	AP
4	Ramesh Nara	1982-09-15	5631 SW 72 ST	narar@ciu.fiu.edu	Prof
3	Daniel Evans	1979-10-07	8754 SW 134 TER	evand@cis.fiu.edu	Prof
\.


--
-- TOC entry 3124 (class 0 OID 0)
-- Dependencies: 196
-- Name: faculty_auto_id; Type: SEQUENCE SET; Schema: public; Owner: spr18_asanc412
--

SELECT pg_catalog.setval('faculty_auto_id', 100, false);


--
-- TOC entry 3107 (class 0 OID 747063)
-- Dependencies: 185
-- Data for Name: faculty_level; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY faculty_level (name, abbreviation) FROM stdin;
Instructor	Instr
Associate Professor	AP
Professor	Prof
\.


--
-- TOC entry 3109 (class 0 OID 760412)
-- Dependencies: 187
-- Data for Name: grade_values; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY grade_values (id, score, grade) FROM stdin;
1	95 - 100	A
2	90 - 94	A-
3	80 - 89	B+
4	70 - 79	B
5	60 - 69	C
6	0 - 59	D
\.


--
-- TOC entry 3108 (class 0 OID 760404)
-- Dependencies: 186
-- Data for Name: school_probs; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY school_probs (school_code, school, probs) FROM stdin;
1	CAA	{0.05,0.08,0.18,0.3,0.11,0.28}
2	CAS	{0.06,0.1,0.295,0.36,0.12,0.065}
3	CBA	{0.05,0.11,0.35,0.32,0.12,0.05}
4	CE	{0.04,0.05,0.08,0.3,0.42,0.11}
5	CEC	{0.05,0.11,0.35,0.32,0.12,0.05}
6	HC	{0.12,0.1,0.23,0.4,0.06,0.09}
7	CL	{0.07,0.09,0.24,0.4,0.12,0.08}
8	CNHS	{0.08,0.1,0.295,0.34,0.12,0.065}
9	SJMC	{0.09,0.11,0.31,0.32,0.12,0.05}
\.


--
-- TOC entry 3110 (class 0 OID 760420)
-- Dependencies: 188
-- Data for Name: simulated_records; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY simulated_records (record_id, school, grade) FROM stdin;
5	CAA	A
7	CAA	A
8	CAA	A
9	CAA	A
12	CAA	A
22	CAA	A
34	CAA	A
41	CAA	A
47	CAA	A
53	CAA	A
56	CAA	A
58	CAA	A
59	CAA	A
70	CAA	A-
97	CAA	A-
98	CAA	A-
101	CAA	A-
107	CAA	A-
108	CAA	A-
114	CAA	A-
115	CAA	A-
116	CAA	A-
126	CAA	A-
130	CAA	A-
134	CAA	A-
136	CAA	A-
140	CAA	A-
141	CAA	A-
146	CAA	A-
158	CAA	A-
171	CAA	A-
180	CAA	A-
186	CAA	A-
190	CAA	B+
197	CAA	B+
200	CAA	B+
202	CAA	B+
210	CAA	B+
211	CAA	B+
212	CAA	B+
223	CAA	B+
247	CAA	B+
252	CAA	B+
255	CAA	B+
264	CAA	B+
269	CAA	B+
273	CAA	B+
274	CAA	B+
279	CAA	B+
281	CAA	B+
284	CAA	B+
287	CAA	B+
301	CAA	B+
302	CAA	B+
305	CAA	B+
324	CAA	B+
325	CAA	B+
328	CAA	B+
329	CAA	B+
331	CAA	B+
334	CAA	B+
337	CAA	B+
342	CAA	B+
356	CAA	B+
359	CAA	B+
362	CAA	B+
374	CAA	B+
377	CAA	B+
398	CAA	B+
400	CAA	B+
404	CAA	B+
406	CAA	B+
407	CAA	B+
434	CAA	B+
436	CAA	B+
448	CAA	B+
458	CAA	B+
459	CAA	B+
465	CAA	B
474	CAA	B
485	CAA	B
489	CAA	B
491	CAA	B
499	CAA	B
511	CAA	B
517	CAA	B
522	CAA	B
544	CAA	B
546	CAA	B
551	CAA	B
555	CAA	B
560	CAA	B
574	CAA	B
586	CAA	B
587	CAA	B
620	CAA	B
621	CAA	B
632	CAA	B
639	CAA	B
654	CAA	B
657	CAA	B
658	CAA	B
663	CAA	B
664	CAA	B
688	CAA	B
690	CAA	B
703	CAA	B
704	CAA	B
735	CAA	B
745	CAA	B
749	CAA	B
750	CAA	B
752	CAA	B
759	CAA	B
763	CAA	B
765	CAA	B
767	CAA	B
773	CAA	B
778	CAA	B
792	CAA	B
803	CAA	B
811	CAA	B
814	CAA	B
816	CAA	B
817	CAA	B
821	CAA	B
824	CAA	B
844	CAA	B
846	CAA	B
872	CAA	B
879	CAA	B
882	CAA	B
897	CAA	B
898	CAA	B
913	CAA	B
917	CAA	B
924	CAA	B
927	CAA	B
936	CAA	B
945	CAA	B
953	CAA	B
962	CAA	B
975	CAA	B
978	CAA	B
980	CAA	B
991	CAA	B
1001	CAA	B
1003	CAA	B
1023	CAA	B
1026	CAA	B
1059	CAA	B
1073	CAA	B
1088	CAA	B
1092	CAA	C
1099	CAA	C
1117	CAA	C
1137	CAA	C
1157	CAA	C
1160	CAA	C
1161	CAA	C
1176	CAA	C
1186	CAA	C
1189	CAA	C
1190	CAA	C
1195	CAA	C
1201	CAA	C
1203	CAA	C
1204	CAA	C
1205	CAA	C
1240	CAA	C
1250	CAA	C
1262	CAA	C
1264	CAA	C
1267	CAA	C
1269	CAA	C
1275	CAA	C
1284	CAA	C
1296	CAA	C
1311	CAA	C
1325	CAA	C
1329	CAA	C
1331	CAA	D
1335	CAA	D
1357	CAA	D
1373	CAA	D
1376	CAA	D
1382	CAA	D
1387	CAA	D
1388	CAA	D
1389	CAA	D
1393	CAA	D
1395	CAA	D
1399	CAA	D
1401	CAA	D
1433	CAA	D
1487	CAA	D
1514	CAA	D
1519	CAA	D
1538	CAA	D
1544	CAA	D
1545	CAA	D
1552	CAA	D
1557	CAA	D
1565	CAA	D
1574	CAA	D
1578	CAA	D
1579	CAA	D
1597	CAA	D
1598	CAA	D
1615	CAA	D
1620	CAA	D
1623	CAA	D
1638	CAA	D
1639	CAA	D
1640	CAA	D
1643	CAA	D
1662	CAA	D
1664	CAA	D
1674	CAA	D
1681	CAA	D
1688	CAA	D
1697	CAA	D
1707	CAA	D
1710	CAA	D
1713	CAA	D
1735	CAA	D
1740	CAA	D
1769	CAA	D
1779	CAA	D
1786	CAA	D
1810	CAA	D
1812	CAA	D
1821	CAA	D
1826	CAA	D
1834	CAA	D
1837	CAA	D
1839	CAA	D
1842	CAA	D
1850	CAA	D
1869	CAA	D
1896	CAA	D
1903	CAA	D
1926	CAA	D
1927	CAA	D
1951	CAA	D
1966	CAA	D
1967	CAA	D
1972	CAA	D
1980	CAA	D
1988	CAA	D
1996	CAA	D
6	CAS	A
27	CAS	A
28	CAS	A
38	CAS	A
45	CAS	A
49	CAS	A
54	CAS	A
69	CAS	A
71	CAS	A
83	CAS	A
86	CAS	A
118	CAS	A
119	CAS	A
127	CAS	A
139	CAS	A-
143	CAS	A-
150	CAS	A-
155	CAS	A-
156	CAS	A-
178	CAS	A-
187	CAS	A-
207	CAS	A-
213	CAS	A-
217	CAS	A-
227	CAS	A-
237	CAS	A-
246	CAS	A-
258	CAS	A-
260	CAS	A-
275	CAS	A-
292	CAS	A-
293	CAS	A-
320	CAS	A-
326	CAS	A-
335	CAS	A-
366	CAS	A-
368	CAS	A-
375	CAS	B+
381	CAS	B+
386	CAS	B+
394	CAS	B+
416	CAS	B+
431	CAS	B+
441	CAS	B+
450	CAS	B+
451	CAS	B+
460	CAS	B+
464	CAS	B+
467	CAS	B+
469	CAS	B+
470	CAS	B+
472	CAS	B+
484	CAS	B+
486	CAS	B+
492	CAS	B+
502	CAS	B+
505	CAS	B+
506	CAS	B+
523	CAS	B+
550	CAS	B+
552	CAS	B+
556	CAS	B+
558	CAS	B+
562	CAS	B+
576	CAS	B+
593	CAS	B+
594	CAS	B+
597	CAS	B+
603	CAS	B+
606	CAS	B+
618	CAS	B+
643	CAS	B+
645	CAS	B+
673	CAS	B+
674	CAS	B+
677	CAS	B+
680	CAS	B+
702	CAS	B+
737	CAS	B+
739	CAS	B+
744	CAS	B+
746	CAS	B+
756	CAS	B+
758	CAS	B+
766	CAS	B+
777	CAS	B+
786	CAS	B+
790	CAS	B+
798	CAS	B+
820	CAS	B+
838	CAS	B+
843	CAS	B+
847	CAS	B+
856	CAS	B+
863	CAS	B+
876	CAS	B+
877	CAS	B+
880	CAS	B+
891	CAS	B+
905	CAS	B+
910	CAS	B+
911	CAS	B+
914	CAS	B+
920	CAS	B+
921	CAS	B
923	CAS	B
930	CAS	B
992	CAS	B
995	CAS	B
999	CAS	B
1035	CAS	B
1038	CAS	B
1045	CAS	B
1048	CAS	B
1050	CAS	B
1053	CAS	B
1069	CAS	B
1070	CAS	B
1072	CAS	B
1085	CAS	B
1087	CAS	B
1091	CAS	B
1103	CAS	B
1109	CAS	B
1115	CAS	B
1122	CAS	B
1150	CAS	B
1159	CAS	B
1164	CAS	B
1170	CAS	B
1171	CAS	B
1181	CAS	B
1185	CAS	B
1187	CAS	B
1192	CAS	B
1193	CAS	B
1194	CAS	B
1206	CAS	B
1211	CAS	B
1216	CAS	B
1221	CAS	B
1225	CAS	B
1234	CAS	B
1248	CAS	B
1286	CAS	B
1298	CAS	B
1310	CAS	B
1322	CAS	B
1326	CAS	B
1359	CAS	B
1361	CAS	B
1384	CAS	B
1405	CAS	B
1410	CAS	B
1411	CAS	B
1421	CAS	B
1422	CAS	B
1428	CAS	B
1446	CAS	B
1448	CAS	B
1452	CAS	B
1456	CAS	B
1459	CAS	B
1467	CAS	B
1472	CAS	B
1474	CAS	B
1475	CAS	B
1479	CAS	B
1482	CAS	B
1488	CAS	B
1495	CAS	B
1500	CAS	B
1523	CAS	B
1525	CAS	B
1539	CAS	B
1546	CAS	B
1548	CAS	B
1559	CAS	B
1570	CAS	B
1576	CAS	B
1583	CAS	B
1585	CAS	B
1612	CAS	B
1617	CAS	B
1622	CAS	B
1646	CAS	B
1659	CAS	C
1661	CAS	C
1678	CAS	C
1683	CAS	C
1690	CAS	C
1694	CAS	C
1701	CAS	C
1708	CAS	C
1714	CAS	C
1718	CAS	C
1720	CAS	C
1726	CAS	C
1727	CAS	C
1729	CAS	C
1760	CAS	C
1772	CAS	C
1781	CAS	C
1788	CAS	C
1794	CAS	C
1795	CAS	C
1809	CAS	C
1813	CAS	C
1828	CAS	C
1855	CAS	C
1857	CAS	C
1859	CAS	C
1860	CAS	C
1863	CAS	D
1870	CAS	D
1881	CAS	D
1883	CAS	D
1884	CAS	D
1901	CAS	D
1907	CAS	D
1915	CAS	D
1928	CAS	D
1929	CAS	D
1956	CAS	D
1968	CAS	D
1977	CAS	D
1979	CAS	D
11	CBA	A
16	CBA	A
23	CBA	A
25	CBA	A
35	CBA	A
40	CBA	A
44	CBA	A
46	CBA	A
51	CBA	A
55	CBA	A
57	CBA	A
61	CBA	A-
77	CBA	A-
95	CBA	A-
106	CBA	A-
111	CBA	A-
144	CBA	A-
145	CBA	A-
152	CBA	A-
161	CBA	A-
163	CBA	A-
165	CBA	A-
169	CBA	A-
175	CBA	A-
194	CBA	A-
198	CBA	A-
214	CBA	A-
220	CBA	A-
226	CBA	A-
229	CBA	A-
232	CBA	A-
233	CBA	A-
234	CBA	A-
239	CBA	A-
248	CBA	A-
259	CBA	B+
262	CBA	B+
263	CBA	B+
291	CBA	B+
313	CBA	B+
344	CBA	B+
364	CBA	B+
369	CBA	B+
370	CBA	B+
387	CBA	B+
388	CBA	B+
393	CBA	B+
397	CBA	B+
409	CBA	B+
413	CBA	B+
437	CBA	B+
440	CBA	B+
442	CBA	B+
455	CBA	B+
463	CBA	B+
476	CBA	B+
498	CBA	B+
500	CBA	B+
501	CBA	B+
512	CBA	B+
518	CBA	B+
521	CBA	B+
524	CBA	B+
533	CBA	B+
534	CBA	B+
548	CBA	B+
554	CBA	B+
557	CBA	B+
561	CBA	B+
573	CBA	B+
581	CBA	B+
583	CBA	B+
615	CBA	B+
637	CBA	B+
655	CBA	B+
659	CBA	B+
665	CBA	B+
666	CBA	B+
676	CBA	B+
678	CBA	B+
679	CBA	B+
682	CBA	B+
685	CBA	B+
691	CBA	B+
698	CBA	B+
723	CBA	B+
724	CBA	B+
730	CBA	B+
741	CBA	B+
751	CBA	B+
754	CBA	B+
768	CBA	B+
769	CBA	B+
785	CBA	B+
789	CBA	B+
791	CBA	B+
804	CBA	B+
813	CBA	B+
840	CBA	B+
842	CBA	B+
874	CBA	B+
886	CBA	B+
908	CBA	B+
941	CBA	B+
966	CBA	B+
981	CBA	B+
997	CBA	B+
1030	CBA	B+
1031	CBA	B+
1042	CBA	B+
1044	CBA	B+
1047	CBA	B
1056	CBA	B
1065	CBA	B
1074	CBA	B
1078	CBA	B
1082	CBA	B
1104	CBA	B
1105	CBA	B
1119	CBA	B
1120	CBA	B
1144	CBA	B
1151	CBA	B
1167	CBA	B
1173	CBA	B
1202	CBA	B
1227	CBA	B
1239	CBA	B
1241	CBA	B
1253	CBA	B
1259	CBA	B
1316	CBA	B
1317	CBA	B
1336	CBA	B
1345	CBA	B
1365	CBA	B
1377	CBA	B
1378	CBA	B
1383	CBA	B
1394	CBA	B
1397	CBA	B
1408	CBA	B
1424	CBA	B
1425	CBA	B
1454	CBA	B
1458	CBA	B
1491	CBA	B
1492	CBA	B
1493	CBA	B
1506	CBA	B
1517	CBA	B
1521	CBA	B
1531	CBA	B
1534	CBA	B
1535	CBA	B
1536	CBA	B
1540	CBA	B
1563	CBA	B
1577	CBA	B
1582	CBA	B
1586	CBA	B
1587	CBA	B
1590	CBA	B
1592	CBA	B
1593	CBA	B
1594	CBA	B
1599	CBA	B
1601	CBA	B
1613	CBA	B
1614	CBA	B
1627	CBA	B
1628	CBA	B
1633	CBA	B
1634	CBA	B
1645	CBA	B
1652	CBA	B
1655	CBA	B
1656	CBA	B
1667	CBA	B
1668	CBA	B
1671	CBA	B
1679	CBA	C
1712	CBA	C
1716	CBA	C
1719	CBA	C
1725	CBA	C
1730	CBA	C
1761	CBA	C
1762	CBA	C
1796	CBA	C
1801	CBA	C
1803	CBA	C
1804	CBA	C
1862	CBA	C
1865	CBA	C
1866	CBA	C
1874	CBA	C
1879	CBA	C
1885	CBA	C
1894	CBA	C
1897	CBA	C
1899	CBA	C
1904	CBA	C
1916	CBA	C
1923	CBA	C
1932	CBA	C
1936	CBA	C
1938	CBA	D
1942	CBA	D
1952	CBA	D
1962	CBA	D
1974	CBA	D
1981	CBA	D
1982	CBA	D
1984	CBA	D
1985	CBA	D
1989	CBA	D
1998	CBA	D
17	CE	A
18	CE	A
24	CE	A
31	CE	A
52	CE	A
63	CE	A
68	CE	A
76	CE	A
79	CE	A
84	CE	A-
93	CE	A-
112	CE	A-
113	CE	A-
125	CE	A-
131	CE	A-
138	CE	A-
181	CE	A-
219	CE	A-
222	CE	A-
236	CE	A-
241	CE	B+
250	CE	B+
277	CE	B+
286	CE	B+
289	CE	B+
294	CE	B+
296	CE	B+
298	CE	B+
304	CE	B+
318	CE	B+
319	CE	B+
336	CE	B+
339	CE	B+
348	CE	B+
351	CE	B+
358	CE	B+
385	CE	B+
389	CE	B+
390	CE	B
402	CE	B
408	CE	B
412	CE	B
419	CE	B
428	CE	B
449	CE	B
453	CE	B
504	CE	B
510	CE	B
525	CE	B
526	CE	B
527	CE	B
529	CE	B
530	CE	B
537	CE	B
539	CE	B
541	CE	B
570	CE	B
571	CE	B
575	CE	B
579	CE	B
614	CE	B
616	CE	B
624	CE	B
634	CE	B
635	CE	B
651	CE	B
653	CE	B
671	CE	B
707	CE	B
715	CE	B
716	CE	B
722	CE	B
728	CE	B
738	CE	B
753	CE	B
762	CE	B
774	CE	B
775	CE	B
776	CE	B
794	CE	B
796	CE	B
801	CE	B
819	CE	B
825	CE	B
836	CE	B
841	CE	B
857	CE	B
859	CE	B
865	CE	B
868	CE	B
871	CE	B
890	CE	B
892	CE	B
925	CE	B
926	CE	B
934	CE	B
938	CE	B
943	CE	B
952	CE	B
957	CE	B
959	CE	B
961	CE	B
982	CE	B
985	CE	B
987	CE	C
996	CE	C
1008	CE	C
1021	CE	C
1029	CE	C
1037	CE	C
1041	CE	C
1046	CE	C
1079	CE	C
1093	CE	C
1112	CE	C
1113	CE	C
1124	CE	C
1129	CE	C
1136	CE	C
1139	CE	C
1149	CE	C
1169	CE	C
1172	CE	C
1197	CE	C
1212	CE	C
1213	CE	C
1226	CE	C
1230	CE	C
1244	CE	C
1249	CE	C
1251	CE	C
1252	CE	C
1261	CE	C
1268	CE	C
1274	CE	C
1276	CE	C
1302	CE	C
1303	CE	C
1313	CE	C
1323	CE	C
1324	CE	C
1341	CE	C
1350	CE	C
1353	CE	C
1364	CE	C
1380	CE	C
1381	CE	C
1418	CE	C
1426	CE	C
1432	CE	C
1449	CE	C
1451	CE	C
1455	CE	C
1470	CE	C
1481	CE	C
1490	CE	C
1494	CE	C
1499	CE	C
1502	CE	C
1504	CE	C
1509	CE	C
1510	CE	C
1511	CE	C
1512	CE	C
1513	CE	C
1515	CE	C
1518	CE	C
1541	CE	C
1556	CE	C
1573	CE	C
1600	CE	C
1610	CE	C
1616	CE	C
1629	CE	C
1630	CE	C
1682	CE	C
1686	CE	C
1691	CE	C
1699	CE	C
1702	CE	C
1705	CE	C
1711	CE	C
1715	CE	C
1723	CE	C
1724	CE	C
1728	CE	C
1731	CE	C
1739	CE	C
1743	CE	C
1754	CE	C
1757	CE	C
1758	CE	C
1767	CE	C
1774	CE	C
1780	CE	C
1789	CE	C
1793	CE	C
1799	CE	D
1805	CE	D
1818	CE	D
1829	CE	D
1840	CE	D
1847	CE	D
1868	CE	D
1871	CE	D
1875	CE	D
1878	CE	D
1889	CE	D
1895	CE	D
1900	CE	D
1912	CE	D
1914	CE	D
1922	CE	D
1925	CE	D
1933	CE	D
1940	CE	D
1957	CE	D
1969	CE	D
1983	CE	D
1997	CE	D
1999	CE	D
2	CEC	A
3	CEC	A
4	CEC	A
30	CEC	A
74	CEC	A
89	CEC	A
94	CEC	A
96	CEC	A
103	CEC	A
132	CEC	A
135	CEC	A-
157	CEC	A-
162	CEC	A-
164	CEC	A-
174	CEC	A-
176	CEC	A-
184	CEC	A-
209	CEC	A-
224	CEC	A-
225	CEC	A-
230	CEC	A-
240	CEC	A-
272	CEC	A-
283	CEC	A-
310	CEC	A-
312	CEC	A-
327	CEC	A-
345	CEC	A-
350	CEC	A-
361	CEC	A-
363	CEC	A-
401	CEC	A-
411	CEC	A-
414	CEC	B+
421	CEC	B+
423	CEC	B+
427	CEC	B+
430	CEC	B+
452	CEC	B+
461	CEC	B+
482	CEC	B+
496	CEC	B+
509	CEC	B+
519	CEC	B+
531	CEC	B+
540	CEC	B+
542	CEC	B+
547	CEC	B+
568	CEC	B+
582	CEC	B+
588	CEC	B+
596	CEC	B+
602	CEC	B+
604	CEC	B+
609	CEC	B+
610	CEC	B+
619	CEC	B+
626	CEC	B+
630	CEC	B+
631	CEC	B+
636	CEC	B+
642	CEC	B+
648	CEC	B+
656	CEC	B+
661	CEC	B+
662	CEC	B+
670	CEC	B+
684	CEC	B+
687	CEC	B+
692	CEC	B+
695	CEC	B+
697	CEC	B+
700	CEC	B+
706	CEC	B+
709	CEC	B+
717	CEC	B+
720	CEC	B+
725	CEC	B+
726	CEC	B+
740	CEC	B+
747	CEC	B+
784	CEC	B+
787	CEC	B+
806	CEC	B+
809	CEC	B+
823	CEC	B+
830	CEC	B+
831	CEC	B+
855	CEC	B+
864	CEC	B+
873	CEC	B+
878	CEC	B+
885	CEC	B+
889	CEC	B+
893	CEC	B+
900	CEC	B+
901	CEC	B+
904	CEC	B+
909	CEC	B+
929	CEC	B+
935	CEC	B+
951	CEC	B+
958	CEC	B+
960	CEC	B+
969	CEC	B+
972	CEC	B
998	CEC	B
1006	CEC	B
1013	CEC	B
1015	CEC	B
1019	CEC	B
1036	CEC	B
1043	CEC	B
1057	CEC	B
1075	CEC	B
1083	CEC	B
1096	CEC	B
1098	CEC	B
1100	CEC	B
1118	CEC	B
1123	CEC	B
1127	CEC	B
1128	CEC	B
1130	CEC	B
1132	CEC	B
1146	CEC	B
1147	CEC	B
1148	CEC	B
1154	CEC	B
1163	CEC	B
1178	CEC	B
1182	CEC	B
1188	CEC	B
1198	CEC	B
1209	CEC	B
1218	CEC	B
1246	CEC	B
1255	CEC	B
1265	CEC	B
1277	CEC	B
1278	CEC	B
1292	CEC	B
1294	CEC	B
1300	CEC	B
1318	CEC	B
1338	CEC	B
1339	CEC	B
1342	CEC	B
1347	CEC	B
1371	CEC	B
1372	CEC	B
1374	CEC	B
1400	CEC	B
1402	CEC	B
1442	CEC	B
1461	CEC	B
1520	CEC	B
1526	CEC	B
1529	CEC	B
1532	CEC	B
1547	CEC	B
1551	CEC	B
1553	CEC	B
1560	CEC	B
1562	CEC	B
1568	CEC	B
1569	CEC	B
1572	CEC	B
1581	CEC	B
1584	CEC	B
1596	CEC	B
1669	CEC	C
1680	CEC	C
1684	CEC	C
1687	CEC	C
1695	CEC	C
1698	CEC	C
1700	CEC	C
1738	CEC	C
1748	CEC	C
1756	CEC	C
1770	CEC	C
1773	CEC	C
1782	CEC	C
1785	CEC	C
1791	CEC	C
1792	CEC	C
1797	CEC	C
1807	CEC	C
1815	CEC	C
1816	CEC	C
1819	CEC	C
1822	CEC	C
1823	CEC	C
1830	CEC	C
1835	CEC	C
1849	CEC	D
1852	CEC	D
1890	CEC	D
1891	CEC	D
1935	CEC	D
1944	CEC	D
1959	CEC	D
1963	CEC	D
1970	CEC	D
2000	CEC	D
13	HC	A
19	HC	A
29	HC	A
37	HC	A
39	HC	A
43	HC	A
62	HC	A
66	HC	A
80	HC	A
90	HC	A
99	HC	A
100	HC	A
102	HC	A
105	HC	A
109	HC	A
121	HC	A
122	HC	A
147	HC	A
148	HC	A
168	HC	A
172	HC	A
185	HC	A
189	HC	A
191	HC	A
192	HC	A
215	HC	A
231	HC	A
235	HC	A
242	HC	A
243	HC	A-
249	HC	A-
254	HC	A-
256	HC	A-
265	HC	A-
266	HC	A-
288	HC	A-
290	HC	A-
297	HC	A-
306	HC	A-
307	HC	A-
309	HC	A-
311	HC	A-
330	HC	A-
333	HC	A-
353	HC	A-
360	HC	A-
372	HC	A-
376	HC	A-
379	HC	A-
391	HC	A-
403	HC	A-
405	HC	A-
418	HC	A-
429	HC	B+
432	HC	B+
439	HC	B+
454	HC	B+
456	HC	B+
457	HC	B+
468	HC	B+
480	HC	B+
493	HC	B+
520	HC	B+
528	HC	B+
549	HC	B+
553	HC	B+
566	HC	B+
567	HC	B+
572	HC	B+
577	HC	B+
580	HC	B+
612	HC	B+
623	HC	B+
629	HC	B+
646	HC	B+
647	HC	B+
649	HC	B+
652	HC	B+
668	HC	B+
683	HC	B+
686	HC	B+
689	HC	B+
705	HC	B+
714	HC	B+
718	HC	B+
733	HC	B+
736	HC	B+
743	HC	B+
748	HC	B+
755	HC	B+
761	HC	B+
764	HC	B+
782	HC	B+
783	HC	B+
793	HC	B+
802	HC	B+
805	HC	B+
810	HC	B+
818	HC	B+
822	HC	B+
827	HC	B+
829	HC	B+
832	HC	B+
834	HC	B+
837	HC	B+
848	HC	B+
851	HC	B+
858	HC	B+
860	HC	B
861	HC	B
881	HC	B
883	HC	B
888	HC	B
896	HC	B
899	HC	B
902	HC	B
903	HC	B
915	HC	B
916	HC	B
922	HC	B
942	HC	B
963	HC	B
964	HC	B
977	HC	B
983	HC	B
988	HC	B
993	HC	B
1007	HC	B
1010	HC	B
1011	HC	B
1016	HC	B
1017	HC	B
1025	HC	B
1032	HC	B
1049	HC	B
1052	HC	B
1066	HC	B
1077	HC	B
1081	HC	B
1095	HC	B
1101	HC	B
1102	HC	B
1106	HC	B
1107	HC	B
1143	HC	B
1155	HC	B
1158	HC	B
1165	HC	B
1166	HC	B
1174	HC	B
1175	HC	B
1177	HC	B
1184	HC	B
1191	HC	B
1199	HC	B
1223	HC	B
1228	HC	B
1231	HC	B
1280	HC	B
1282	HC	B
1301	HC	B
1306	HC	B
1307	HC	B
1319	HC	B
1320	HC	B
1321	HC	B
1330	HC	B
1349	HC	B
1358	HC	B
1375	HC	B
1379	HC	B
1391	HC	B
1404	HC	B
1406	HC	B
1412	HC	B
1415	HC	B
1430	HC	B
1436	HC	B
1439	HC	B
1444	HC	B
1453	HC	B
1463	HC	B
1464	HC	B
1465	HC	B
1471	HC	B
1476	HC	B
1485	HC	B
1486	HC	B
1496	HC	B
1516	HC	B
1530	HC	B
1555	HC	B
1591	HC	B
1605	HC	B
1608	HC	B
1611	HC	B
1626	HC	B
1635	HC	B
1663	HC	B
1672	HC	B
1675	HC	B
1721	HC	B
1733	HC	B
1734	HC	B
1736	HC	C
1745	HC	C
1747	HC	C
1750	HC	C
1751	HC	C
1765	HC	C
1778	HC	C
1784	HC	C
1787	HC	C
1798	HC	C
1802	HC	C
1808	HC	C
1811	HC	C
1825	HC	C
1827	HC	D
1838	HC	D
1844	HC	D
1846	HC	D
1848	HC	D
1851	HC	D
1853	HC	D
1854	HC	D
1864	HC	D
1873	HC	D
1880	HC	D
1886	HC	D
1892	HC	D
1893	HC	D
1920	HC	D
1934	HC	D
1946	HC	D
1958	HC	D
1965	HC	D
1973	HC	D
1990	HC	D
1993	HC	D
1	CL	A
10	CL	A
14	CL	A
48	CL	A
64	CL	A
67	CL	A
110	CL	A
117	CL	A
120	CL	A
123	CL	A
128	CL	A
129	CL	A
154	CL	A
166	CL	A
183	CL	A-
193	CL	A-
204	CL	A-
218	CL	A-
221	CL	A-
238	CL	A-
253	CL	A-
257	CL	A-
280	CL	A-
303	CL	A-
315	CL	A-
316	CL	A-
317	CL	A-
332	CL	A-
338	CL	A-
340	CL	A-
349	CL	A-
355	CL	A-
357	CL	B+
378	CL	B+
382	CL	B+
417	CL	B+
425	CL	B+
426	CL	B+
445	CL	B+
471	CL	B+
475	CL	B+
481	CL	B+
490	CL	B+
543	CL	B+
545	CL	B+
559	CL	B+
563	CL	B+
564	CL	B+
585	CL	B+
589	CL	B+
591	CL	B+
598	CL	B+
607	CL	B+
617	CL	B+
625	CL	B+
627	CL	B+
638	CL	B+
650	CL	B+
660	CL	B+
675	CL	B+
681	CL	B+
694	CL	B+
710	CL	B+
727	CL	B+
731	CL	B+
742	CL	B+
757	CL	B+
788	CL	B+
808	CL	B+
828	CL	B+
835	CL	B+
845	CL	B+
849	CL	B+
853	CL	B+
895	CL	B+
928	CL	B+
932	CL	B+
933	CL	B+
939	CL	B+
940	CL	B+
949	CL	B
955	CL	B
956	CL	B
965	CL	B
967	CL	B
968	CL	B
974	CL	B
986	CL	B
1000	CL	B
1018	CL	B
1024	CL	B
1028	CL	B
1033	CL	B
1054	CL	B
1055	CL	B
1060	CL	B
1063	CL	B
1067	CL	B
1090	CL	B
1094	CL	B
1108	CL	B
1110	CL	B
1114	CL	B
1131	CL	B
1133	CL	B
1145	CL	B
1156	CL	B
1168	CL	B
1179	CL	B
1196	CL	B
1214	CL	B
1235	CL	B
1236	CL	B
1238	CL	B
1256	CL	B
1257	CL	B
1272	CL	B
1273	CL	B
1288	CL	B
1289	CL	B
1290	CL	B
1304	CL	B
1314	CL	B
1332	CL	B
1343	CL	B
1344	CL	B
1348	CL	B
1354	CL	B
1366	CL	B
1385	CL	B
1386	CL	B
1390	CL	B
1396	CL	B
1398	CL	B
1403	CL	B
1407	CL	B
1420	CL	B
1429	CL	B
1435	CL	B
1437	CL	B
1441	CL	B
1443	CL	B
1478	CL	B
1497	CL	B
1498	CL	B
1501	CL	B
1505	CL	B
1524	CL	B
1528	CL	B
1542	CL	B
1550	CL	B
1554	CL	B
1566	CL	B
1580	CL	B
1589	CL	B
1595	CL	B
1602	CL	B
1607	CL	B
1619	CL	B
1624	CL	C
1632	CL	C
1641	CL	C
1653	CL	C
1654	CL	C
1658	CL	C
1670	CL	C
1677	CL	C
1692	CL	C
1696	CL	C
1704	CL	C
1717	CL	C
1741	CL	C
1742	CL	C
1744	CL	C
1746	CL	C
1752	CL	C
1755	CL	C
1759	CL	C
1771	CL	C
1776	CL	C
1820	CL	C
1832	CL	C
1841	CL	C
1856	CL	D
1861	CL	D
1908	CL	D
1917	CL	D
1941	CL	D
1945	CL	D
1948	CL	D
1953	CL	D
1954	CL	D
1955	CL	D
1964	CL	D
1971	CL	D
1978	CL	D
1986	CL	D
1994	CL	D
15	CNHS	A
20	CNHS	A
32	CNHS	A
33	CNHS	A
36	CNHS	A
50	CNHS	A
75	CNHS	A
78	CNHS	A
82	CNHS	A
85	CNHS	A
87	CNHS	A
92	CNHS	A
124	CNHS	A
133	CNHS	A
137	CNHS	A
151	CNHS	A
153	CNHS	A-
179	CNHS	A-
188	CNHS	A-
196	CNHS	A-
201	CNHS	A-
203	CNHS	A-
205	CNHS	A-
208	CNHS	A-
244	CNHS	A-
261	CNHS	A-
270	CNHS	A-
276	CNHS	A-
278	CNHS	A-
282	CNHS	A-
299	CNHS	A-
300	CNHS	A-
343	CNHS	A-
347	CNHS	A-
354	CNHS	A-
371	CNHS	A-
373	CNHS	B+
380	CNHS	B+
383	CNHS	B+
399	CNHS	B+
415	CNHS	B+
435	CNHS	B+
443	CNHS	B+
444	CNHS	B+
446	CNHS	B+
447	CNHS	B+
462	CNHS	B+
473	CNHS	B+
478	CNHS	B+
483	CNHS	B+
488	CNHS	B+
497	CNHS	B+
503	CNHS	B+
515	CNHS	B+
536	CNHS	B+
578	CNHS	B+
584	CNHS	B+
590	CNHS	B+
600	CNHS	B+
601	CNHS	B+
605	CNHS	B+
613	CNHS	B+
628	CNHS	B+
640	CNHS	B+
641	CNHS	B+
667	CNHS	B+
693	CNHS	B+
708	CNHS	B+
712	CNHS	B+
772	CNHS	B+
779	CNHS	B+
780	CNHS	B+
781	CNHS	B+
799	CNHS	B+
812	CNHS	B+
833	CNHS	B+
854	CNHS	B+
862	CNHS	B+
869	CNHS	B+
875	CNHS	B+
887	CNHS	B+
906	CNHS	B+
907	CNHS	B+
912	CNHS	B+
944	CNHS	B+
946	CNHS	B+
971	CNHS	B+
973	CNHS	B+
979	CNHS	B+
994	CNHS	B+
1004	CNHS	B+
1005	CNHS	B+
1009	CNHS	B+
1012	CNHS	B+
1020	CNHS	B+
1027	CNHS	B
1039	CNHS	B
1040	CNHS	B
1058	CNHS	B
1061	CNHS	B
1062	CNHS	B
1076	CNHS	B
1080	CNHS	B
1086	CNHS	B
1111	CNHS	B
1125	CNHS	B
1126	CNHS	B
1135	CNHS	B
1140	CNHS	B
1141	CNHS	B
1142	CNHS	B
1180	CNHS	B
1207	CNHS	B
1210	CNHS	B
1217	CNHS	B
1219	CNHS	B
1229	CNHS	B
1232	CNHS	B
1233	CNHS	B
1237	CNHS	B
1242	CNHS	B
1258	CNHS	B
1260	CNHS	B
1266	CNHS	B
1279	CNHS	B
1285	CNHS	B
1291	CNHS	B
1293	CNHS	B
1299	CNHS	B
1308	CNHS	B
1312	CNHS	B
1328	CNHS	B
1333	CNHS	B
1337	CNHS	B
1360	CNHS	B
1362	CNHS	B
1363	CNHS	B
1370	CNHS	B
1392	CNHS	B
1409	CNHS	B
1414	CNHS	B
1417	CNHS	B
1427	CNHS	B
1431	CNHS	B
1438	CNHS	B
1440	CNHS	B
1445	CNHS	B
1447	CNHS	B
1450	CNHS	B
1460	CNHS	B
1469	CNHS	B
1473	CNHS	B
1489	CNHS	B
1503	CNHS	B
1508	CNHS	B
1533	CNHS	B
1558	CNHS	B
1561	CNHS	B
1588	CNHS	B
1604	CNHS	B
1606	CNHS	B
1609	CNHS	B
1618	CNHS	B
1621	CNHS	C
1625	CNHS	C
1647	CNHS	C
1648	CNHS	C
1650	CNHS	C
1651	CNHS	C
1660	CNHS	C
1665	CNHS	C
1673	CNHS	C
1685	CNHS	C
1693	CNHS	C
1722	CNHS	C
1763	CNHS	C
1764	CNHS	C
1766	CNHS	C
1768	CNHS	C
1775	CNHS	C
1806	CNHS	C
1814	CNHS	C
1833	CNHS	C
1843	CNHS	C
1858	CNHS	C
1867	CNHS	C
1887	CNHS	C
1888	CNHS	D
1898	CNHS	D
1905	CNHS	D
1909	CNHS	D
1931	CNHS	D
1947	CNHS	D
1950	CNHS	D
1960	CNHS	D
1961	CNHS	D
1991	CNHS	D
1992	CNHS	D
1995	CNHS	D
21	SJMC	A
26	SJMC	A
42	SJMC	A
60	SJMC	A
65	SJMC	A
72	SJMC	A
73	SJMC	A
81	SJMC	A
88	SJMC	A
91	SJMC	A
104	SJMC	A
142	SJMC	A
149	SJMC	A
159	SJMC	A
160	SJMC	A
167	SJMC	A
170	SJMC	A
173	SJMC	A
177	SJMC	A
182	SJMC	A
195	SJMC	A
199	SJMC	A
206	SJMC	A-
216	SJMC	A-
228	SJMC	A-
245	SJMC	A-
251	SJMC	A-
267	SJMC	A-
268	SJMC	A-
271	SJMC	A-
285	SJMC	A-
295	SJMC	A-
308	SJMC	A-
314	SJMC	A-
321	SJMC	A-
322	SJMC	A-
323	SJMC	A-
341	SJMC	A-
346	SJMC	A-
352	SJMC	A-
365	SJMC	A-
367	SJMC	A-
384	SJMC	A-
392	SJMC	A-
395	SJMC	A-
396	SJMC	A-
410	SJMC	A-
420	SJMC	A-
422	SJMC	B+
424	SJMC	B+
433	SJMC	B+
438	SJMC	B+
466	SJMC	B+
477	SJMC	B+
479	SJMC	B+
487	SJMC	B+
494	SJMC	B+
495	SJMC	B+
507	SJMC	B+
508	SJMC	B+
513	SJMC	B+
514	SJMC	B+
516	SJMC	B+
532	SJMC	B+
535	SJMC	B+
538	SJMC	B+
565	SJMC	B+
569	SJMC	B+
592	SJMC	B+
595	SJMC	B+
599	SJMC	B+
608	SJMC	B+
611	SJMC	B+
622	SJMC	B+
633	SJMC	B+
644	SJMC	B+
669	SJMC	B+
672	SJMC	B+
696	SJMC	B+
699	SJMC	B+
701	SJMC	B+
711	SJMC	B+
713	SJMC	B+
719	SJMC	B+
721	SJMC	B+
729	SJMC	B+
732	SJMC	B+
734	SJMC	B+
760	SJMC	B+
770	SJMC	B+
771	SJMC	B+
795	SJMC	B+
797	SJMC	B+
800	SJMC	B+
807	SJMC	B+
815	SJMC	B+
826	SJMC	B+
839	SJMC	B+
850	SJMC	B+
852	SJMC	B+
866	SJMC	B+
867	SJMC	B+
870	SJMC	B+
884	SJMC	B+
894	SJMC	B+
918	SJMC	B+
919	SJMC	B+
931	SJMC	B+
937	SJMC	B+
947	SJMC	B+
948	SJMC	B+
950	SJMC	B+
954	SJMC	B+
970	SJMC	B+
976	SJMC	B+
984	SJMC	B+
989	SJMC	B+
990	SJMC	B+
1002	SJMC	B+
1014	SJMC	B+
1022	SJMC	B+
1034	SJMC	B+
1051	SJMC	B
1064	SJMC	B
1068	SJMC	B
1071	SJMC	B
1084	SJMC	B
1089	SJMC	B
1097	SJMC	B
1116	SJMC	B
1121	SJMC	B
1134	SJMC	B
1138	SJMC	B
1152	SJMC	B
1153	SJMC	B
1162	SJMC	B
1183	SJMC	B
1200	SJMC	B
1208	SJMC	B
1215	SJMC	B
1220	SJMC	B
1222	SJMC	B
1224	SJMC	B
1243	SJMC	B
1245	SJMC	B
1247	SJMC	B
1254	SJMC	B
1263	SJMC	B
1270	SJMC	B
1271	SJMC	B
1281	SJMC	B
1283	SJMC	B
1287	SJMC	B
1295	SJMC	B
1297	SJMC	B
1305	SJMC	B
1309	SJMC	B
1315	SJMC	B
1327	SJMC	B
1334	SJMC	B
1340	SJMC	B
1346	SJMC	B
1351	SJMC	B
1352	SJMC	B
1355	SJMC	B
1356	SJMC	B
1367	SJMC	B
1368	SJMC	B
1369	SJMC	B
1413	SJMC	B
1416	SJMC	B
1419	SJMC	B
1423	SJMC	B
1434	SJMC	B
1457	SJMC	B
1462	SJMC	B
1466	SJMC	B
1468	SJMC	B
1477	SJMC	B
1480	SJMC	B
1483	SJMC	B
1484	SJMC	B
1507	SJMC	B
1522	SJMC	B
1527	SJMC	B
1537	SJMC	B
1543	SJMC	B
1549	SJMC	B
1564	SJMC	B
1567	SJMC	B
1571	SJMC	B
1575	SJMC	B
1603	SJMC	B
1631	SJMC	B
1636	SJMC	B
1637	SJMC	B
1642	SJMC	B
1644	SJMC	B
1649	SJMC	B
1657	SJMC	C
1666	SJMC	C
1676	SJMC	C
1689	SJMC	C
1703	SJMC	C
1706	SJMC	C
1709	SJMC	C
1732	SJMC	C
1737	SJMC	C
1749	SJMC	C
1753	SJMC	C
1777	SJMC	C
1783	SJMC	C
1790	SJMC	C
1800	SJMC	C
1817	SJMC	C
1824	SJMC	C
1831	SJMC	C
1836	SJMC	C
1845	SJMC	C
1872	SJMC	C
1876	SJMC	C
1877	SJMC	C
1882	SJMC	C
1902	SJMC	C
1906	SJMC	C
1910	SJMC	C
1911	SJMC	C
1913	SJMC	C
1918	SJMC	D
1919	SJMC	D
1921	SJMC	D
1924	SJMC	D
1930	SJMC	D
1937	SJMC	D
1939	SJMC	D
1943	SJMC	D
1949	SJMC	D
1975	SJMC	D
1976	SJMC	D
1987	SJMC	D
\.


--
-- TOC entry 3103 (class 0 OID 742224)
-- Dependencies: 181
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: spr18_asanc412
--

COPY students (student_id, name, date_of_birth, address, email, level) FROM stdin;
3	John Smith	1995-01-09	731 NW 87 AVE	jsmit005@cis.fiu.edu	ugrad
4	Franklin Wong	1995-12-08	638 NW 104 AV	fwong001@cis.fiu.edu	ugrad
5	Jennifer King	1998-11-08	3500 W Flagler ST	jking001@cis.fiu.edu	ugrad
6	Richard Young	1995-12-05	778 SW 87 AVE	ryoun001@cis.fiu.edu	grad
7	Robert Poore	1996-08-22	101 SW 8 ST	rpoor001@cis.fiu.edu	grad
2	Henrie Cage	1994-04-24	1443 NW 7 ST	hcage001@cis.fiu.edu	ugrad
1	Alice Wood	1993-07-13	5637 NW 41 ST	awood001@cis.fiu.edu	ugrad
100	Adrian Sanchez	1994-07-14	8970 W 35th WAY	asanc412@fiu.edu	grad
8	John English	1999-07-31	8421 SW 109 AV	jeng1001@cis.fiu.edu	grad
\.


--
-- TOC entry 3125 (class 0 OID 0)
-- Dependencies: 194
-- Name: students_auto_id; Type: SEQUENCE SET; Schema: public; Owner: spr18_asanc412
--

SELECT pg_catalog.setval('students_auto_id', 113, true);


--
-- TOC entry 2981 (class 2606 OID 807850)
-- Name: _users_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY _users
    ADD CONSTRAINT _users_pkey PRIMARY KEY (username);


--
-- TOC entry 2969 (class 2606 OID 742245)
-- Name: courses_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);


--
-- TOC entry 2971 (class 2606 OID 742255)
-- Name: enroll_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY enroll
    ADD CONSTRAINT enroll_pkey PRIMARY KEY (student_id, course_id);


--
-- TOC entry 2965 (class 2606 OID 742237)
-- Name: faculties_email_key; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY faculties
    ADD CONSTRAINT faculties_email_key UNIQUE (email);


--
-- TOC entry 2967 (class 2606 OID 742235)
-- Name: faculties_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY faculties
    ADD CONSTRAINT faculties_pkey PRIMARY KEY (faculty_id);


--
-- TOC entry 2973 (class 2606 OID 747067)
-- Name: faculty_level_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY faculty_level
    ADD CONSTRAINT faculty_level_pkey PRIMARY KEY (name);


--
-- TOC entry 2977 (class 2606 OID 760419)
-- Name: grade_values_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY grade_values
    ADD CONSTRAINT grade_values_pkey PRIMARY KEY (id);


--
-- TOC entry 2975 (class 2606 OID 760411)
-- Name: school_probs_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY school_probs
    ADD CONSTRAINT school_probs_pkey PRIMARY KEY (school_code);


--
-- TOC entry 2979 (class 2606 OID 760427)
-- Name: simulated_records_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY simulated_records
    ADD CONSTRAINT simulated_records_pkey PRIMARY KEY (record_id);


--
-- TOC entry 2961 (class 2606 OID 742230)
-- Name: students_email_key; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY students
    ADD CONSTRAINT students_email_key UNIQUE (email);


--
-- TOC entry 2963 (class 2606 OID 742228)
-- Name: students_pkey; Type: CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- TOC entry 2982 (class 2606 OID 742279)
-- Name: courses_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_instructor_fkey FOREIGN KEY (instructor) REFERENCES faculties(faculty_id) ON DELETE RESTRICT;


--
-- TOC entry 2984 (class 2606 OID 742261)
-- Name: enroll_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY enroll
    ADD CONSTRAINT enroll_course_id_fkey FOREIGN KEY (course_id) REFERENCES courses(course_id);


--
-- TOC entry 2983 (class 2606 OID 742256)
-- Name: enroll_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: spr18_asanc412
--

ALTER TABLE ONLY enroll
    ADD CONSTRAINT enroll_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(student_id);


--
-- TOC entry 3121 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: root
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM root;
GRANT ALL ON SCHEMA public TO root;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2018-04-03 18:22:25 EDT

--
-- PostgreSQL database dump complete
--

