package com.vsmartengine.invoicebill.User;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserStats {
	private Long userId;
    private String name;
    private byte[] profile;
    private long freeCourses;
    private long paidCourses;
    private long totalStudents;
    private double pending;
	public UserStats(Long userId, String name, byte[] profile, long freeCourses, long paidCourses) {
		super();
		this.userId = userId;
		this.name = name;
		this.profile = profile;
		this.freeCourses = freeCourses;
		this.paidCourses = paidCourses;
	}
	public UserStats(Long userId, String name, byte[] profile, long freeCourses, long paidCourses,double pending ) {
		super();
		this.userId = userId;
		this.name = name;
		this.profile = profile;
		this.freeCourses = freeCourses;
		this.paidCourses = paidCourses;
		this.pending=pending;
	}
}
