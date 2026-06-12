#include "control/robot_controller.hpp"

#include <algorithm>
#include <optional>

#include <pluginlib/class_list_macros.hpp>
#include "hardware_interface/types/hardware_interface_type_values.hpp"

namespace robot_controller
{
    controller_interface::InterfaceConfiguration RobotController::command_interface_configuration() const
    {
        controller_interface::InterfaceConfiguration config;
        config.type = controller_interface::interface_configuration_type::INDIVIDUAL;

        config.names = { // order in here determines array index order
            // Interface names here
        };

        return config;
    }

    
    controller_interface::InterfaceConfiguration RobotController::state_interface_configuration() const
    {
        controller_interface::InterfaceConfiguration config;
        config.type = controller_interface::interface_configuration_type::INDIVIDUAL;

        config.names = {
            // Interface names here
        };

        return config;
    }


    controller_interface::CallbackReturn RobotController::on_init()
    {
        try
        {
            // Receive params from robot_controller.yaml
        }
        catch(const std::exception& e)
        {
            RCLCPP_ERROR(get_node()->get_logger(), "on_init exception: %s", e.what());
            return controller_interface::CallbackReturn::ERROR;
        }
        return controller_interface::CallbackReturn::SUCCESS;
    }


    controller_interface::CallbackReturn RobotController::on_configure(const rclcpp_lifecycle::State &)
    {
        // Do stuff here

        RCLCPP_INFO(get_node()->get_logger(), "Configured RobotController.");
        return controller_interface::CallbackReturn::SUCCESS;
    }


    controller_interface::CallbackReturn RobotController::on_activate(const rclcpp_lifecycle::State &)
    {
        // Do stuff here

        if (command_interfaces_.empty() || state_interfaces_.empty()) {
            RCLCPP_ERROR(get_node()->get_logger(), "Missing controller interfaces.");
            return controller_interface::CallbackReturn::ERROR;
        }

        RCLCPP_INFO(get_node()->get_logger(), "Activated RobotController.");
        return controller_interface::CallbackReturn::SUCCESS;
    }
   

    controller_interface::CallbackReturn RobotController::on_deactivate(const rclcpp_lifecycle::State &)
    {
        // Do stuff here

        RCLCPP_INFO(get_node()->get_logger(), "Deactivated RobotController.");
        return controller_interface::CallbackReturn::SUCCESS;
    }


    controller_interface::return_type RobotController::update(const rclcpp::Time & time, const rclcpp::Duration & period)
    {
        // TODO: Remove these if the variable is used elsewhere
        (void)time; // Silence unused param warning
        (void)period; // Silence unused param warning

        return controller_interface::return_type::OK;
    }

} // namespace robot_controller


PLUGINLIB_EXPORT_CLASS(robot_controller::RobotController,
                       controller_interface::ControllerInterface)
