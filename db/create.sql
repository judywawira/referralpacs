/* Create.sql for ReferralonRails
 * Marc Kohli
 * 12/6/06
 */

drop table if exists encounters;

create table encounters (
	id                 int         not null auto_increment,
	encounter_date datetime    not null,
	patient_id    int         not null,
	study_id       int         not null,
	requester_id   int         not null,
	indication     text        not null,
	findings       text        not null,
	impression     text        not null,
	radiologist_id int         not null,
	xray_id        int         not null,
	invoice        int         not null,
	user_created   int         not null,
	date_created   datetime    not null,
	user_modified  int         not null,
	date_modified  datetime    not null,
	primary key (id)
);

drop table if exists patients;

create table patients (
	id             int          not null auto_increment,
    given_name     varchar(100) not null,
    last_name      varchar(100) not null,
    middle_name    varchar(100) not null,    
	user_created   int          not null,
	date_created   datetime     not null,
	user_modified  int          not null,
	date_modified  datetime     not null,
	primary key (id)
);

drop table if exists users;

create table users (
    id             int         not null auto_increment,
    username       text        not null,
    password       text        not null,
    email          text        not null,
    access_id      int         not null,
    provider_id    int         not null,
	user_created   int         not null,
	date_created   datetime    not null,
	user_modified  int         not null,
	date_modified  datetime    not null,
	primary key (id)
);	
    