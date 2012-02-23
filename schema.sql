/* */
drop table agency;
drop table stops;
drop table routes;
drop table trips;
drop table stop_times;
drop table calendar;
drop table calendar_dates;
drop table fare_attributes;
drop table fare_rules;
drop table shapes;
drop table frequencies;
drop table transfers;
drop table feed_info;


create table agency (
	id int(11) not null primary key auto_increment,
	agency_id varchar(100),
	agency_name varchar(255) not null,
	agency_url varchar(1023) not null,
	agency_timezone varchar(255) not null,
	agency_lang varchar(5),
	agency_phone varchar(255),
	agency_fare_url varchar(1023)
);

create table stops (
	id int(11) not null primary key auto_increment,
	stop_id varchar(100) not null,
	stop_code varchar(255),
	stop_name varchar(255) not null,
	stop_desc varchar(1023),
	stop_lat varchar(50) not null,
	stop_lon varchar(50) not null,
	zone_id varchar(100),
	stop_url varchar(1023),
	location_type varchar(5),
	parent_station varchar(100)
);

create table routes (
        id int(11) not null primary key auto_increment,
	route_id varchar(100) not null,
	agency_id varchar(100),
	route_short_name varchar(200) not null,
	route_long_name varchar(255) not null,
	route_desc varchar(4095),
	route_type varchar(5) not null,
	route_url varchar(1024),
	route_color varchar(50),
	route_text_color varchar(50)
);

create table trips (
	id int(11) not null primary key auto_increment,
	route_id varchar(100) not null,
	service_id varchar(100) not null,
	trip_id varchar(100) not null,
	trip_headsign varchar(255),
	trip_short_name varchar(255),
	direction_id varchar(5),
	block_id varchar(100),
	shape_id varchar(100)
);

create table stop_times (
	id int(11) not null primary key auto_increment,
	trip_id varchar(100) not null,
	arrival_time varchar(50) not null,
	departure_time varchar(50) not null,
	stop_id varchar(100) not null,
	stop_sequence int(11) not null,
	stop_headsign varchar(255),
	pickup_type varchar(5),
	drop_off_type varchar(5),
	shape_dist_traveled varchar(50)
);

create table calendar (
	id int(11) not null primary key auto_increment,
	service_id varchar(100) not null,
	monday varchar(5) not null,
	tuesday varchar(5) not null,
	wednesday varchar(5) not null,
	thursday varchar(5) not null,
	friday varchar(5) not null,
	saturday varchar(5) not null,
	sunday varchar(5) not null,
	start_date varchar(50) not null,
	end_date varchar(50) not null
);

create table calendar_dates (
	id int(11) not null primary key auto_increment,
	service_id varchar(100) not null,
	date varchar(50) not null,
	exception_type varchar(5) not null
);

create table fare_attributes (
	id int(11) not null primary key auto_increment,
	fare_id varchar(100) not null,
	price varchar(50) not null,
	currency_type varchar(50) not null,
	payment_method varchar(5) not null,
	transfers varchar(5) not null,
	transfer_duration varchar(15)
);

create table fare_rules (
	id int(11) not null primary key auto_increment,
	fare_id varchar(100) not null,
	route_id varchar(100),
	origin_id varchar(100),
	destination_id varchar(100),
	contains_id varchar(100)
);

create table shapes (
	id int(11) not null primary key auto_increment,
	shape_id varchar(100) not null,
	shape_pt_lat varchar(50) not null,
	shape_pt_lon varchar(50) not null,
	shape_pt_sequence varchar(15) not null,
	shape_dist_traveled varchar(50)
);

create table frequencies (
	id int(11) not null primary key auto_increment,
	trip_id varchar(100) not null,
	start_time varchar(50) not null,
	end_time varchar(50) not null,
	headway_secs varchar(15) not null,
	exact_times varchar(5)
);

create table transfers (
	id int(11) not null primary key auto_increment,
	from_stop_id varchar(100) not null,
	to_stop_id varchar(100)  not null,
	transfer_type varchar(5) not null,
	min_transfer_time varchar(15)
);

create table feed_info (
	id int(11) not null primary key auto_increment,
	feed_publisher_name varchar(255) not null,
	feed_publisher_url varchar(1023) not null,
	feed_lang varchar(50) not null,
	feed_start_date varchar(50),
	feed_end_date varchar(50),
	feed_version varchar(50)
);
