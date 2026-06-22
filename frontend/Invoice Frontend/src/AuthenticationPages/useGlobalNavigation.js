import { useNavigate } from "react-router-dom";

const useGlobalNavigation = () => {
    const navigate = useNavigate();

    return () => {
        const role = sessionStorage.getItem("role");
        if (role === "ADMIN") {
            navigate("/course/admin/edit");
        } else if (role === "TRAINER") {
            navigate("/AssignedCourses");
        } else {
            navigate("/unauthorized");
        }
    };
};

export default useGlobalNavigation;
