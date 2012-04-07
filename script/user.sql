drop table if exists user;

create table user (
	id int(11) not null primary key auto_increment,
	user_id varchar(100),
	first_name varchar(20) not null,
	last_name varchar(20) not null,
	username varchar(50) not null,
	password varchar(50),
	is_admin int(1),
	address varchar(255),
	email varchar(100),
	phone varchar(20)
);

